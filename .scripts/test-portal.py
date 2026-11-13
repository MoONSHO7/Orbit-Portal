"""Exercise Portal's real TOC in Lua 5.1 using explicit native/host doubles.

These checks cover source integration and ownership, not protected WoW execution.
"""

import argparse
from pathlib import Path
import re
import xml.etree.ElementTree as ET

from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]
FIXTURE = ROOT / ".scripts/tests/portal_native.lua"
CASES = ROOT / ".scripts/tests/portal_cases.lua"
SCANNER_CASES = ROOT / ".scripts/tests/portal_scanner_cases.lua"

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--scanner-only", action="store_true", help="run only focused scanner eligibility cases")
args = parser.parse_args()


def scripts(path):
    if path.suffix == ".xml":
        for element in ET.parse(path).getroot():
            if element.tag.rsplit("}", 1)[-1] in ("Script", "Include"):
                yield from scripts(path.parent / element.attrib["file"].replace("\\", "/"))
    else:
        yield path


loaded = []
for line in (ROOT / "Orbit_Portal.toc").read_text(encoding="utf-8").splitlines():
    line = line.strip()
    if line and not line.startswith("#"):
        loaded.extend(scripts(ROOT / line.replace("\\", "/")))

lua = LuaRuntime()
compile_lua = lua.eval("function(source, name) assert(loadstring(source, name)) end")
for path in ROOT.rglob("*.lua"):
    compile_lua(path.read_text(encoding="utf-8"), str(path))

scenarios = (
    "standalone",
    "disabled",
    "blocked",
    "future",
    "corrupt",
    "legacy",
    "oldhost",
    "loaderror",
    "movementerror",
    "noatlas",
)


def load_runtime(scenario, host_rescan=False):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE.read_text(encoding="utf-8"), scenario)
    if host_rescan:
        lua.execute(r'''
            Orbit.ExternalUIHost.RequestPortalRescan = function() end
            Orbit.EventBus = { On = function(_, event, callback, context, profilerOwner)
                assert(event == "ORBIT_PORTAL_RESCAN_REQUESTED" and not rescanRequest)
                rescanRequest = { callback = callback, context = context, profilerOwner = profilerOwner }
            end }
        ''')
    loader = lua.eval("function(source, name) assert(loadstring(source, name))('Orbit_Portal', addon) end")
    for path in loaded:
        loader(path.read_text(encoding="utf-8"), str(path))
    return lua


if not args.scanner_only:
    for scenario in scenarios:
        lua = load_runtime(scenario)
        lua.execute(CASES.read_text(encoding="utf-8"), scenario)
        print(f"PASS: real TOC/XML {scenario}")
    lua = load_runtime("legacy", host_rescan=True)
    lua.execute(r'''
        local request = assert(rescanRequest)
        local plugin = addon.Portal
        assert(request.context == addon.PortalOrbit and request.profilerOwner == plugin)
        Emit("ADDON_LOADED", "Orbit_Portal")
        Emit("PLAYER_LOGIN")
        plugin:OnLoad()
        plugin:OnEnable()
        local function CheckRescan()
            local before = #messages
            local cache = addon.PortalContext.state.mythicPlusCache
            cache.rescanProbe = true
            request.callback(request.context)
            assert(cache.rescanProbe == nil and #messages == before + 1)
            assert(messages[#messages]:find(addon.L.CMD_PORTAL_SCAN_DONE, 1, true))
        end
        CheckRescan()
        plugin:OnDisable()
        CheckRescan()
        assert(#errors == 0)
    ''')
    print("PASS: hosted rescan delegates while enabled and disabled")

scanner_scenarios = (
    "scanner_human_mage",
    "scanner_draenei_mage",
    "scanner_lightforged_draenei",
    "scanner_nightelf_druid",
    "scanner_gnome_rogue",
    "scanner_engineer",
)
for scenario in scanner_scenarios:
    lua = load_runtime(scenario)
    lua.execute(SCANNER_CASES.read_text(encoding="utf-8"), scenario)
    print(f"PASS: scanner eligibility {scenario}")

if args.scanner_only:
    raise SystemExit(0)

LOCALES = ("enUS", "deDE", "frFR", "esES", "ptBR", "ruRU", "koKR", "zhCN", "zhTW")
LOCALE_ALIASES = {"enGB": "enUS", "esMX": "esES"}
FONT_FACES = {"koKR": "KR", "zhCN": "SC", "zhTW": "TC"}
FONT_DIRECTORY = "Interface\\AddOns\\Orbit_Portal\\Assets\\Fonts\\"
localization = [path for path in loaded if path.parent.name == "Localization"]
fonts = next(path for path in loaded if path.name == "PortalFonts.lua")
keys = set()
for path in (ROOT / "Core").rglob("*.lua"):
    keys.update(re.findall(r"\bL\.([A-Z][A-Z0-9_]*)", path.read_text(encoding="utf-8")))
strings, written = {}, {}
for locale in (*LOCALES, *LOCALE_ALIASES):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute(FIXTURE.read_text(encoding="utf-8"), "locale")
    lua.execute('local locale = ...; GetLocale = function() return locale end; _G["LOCALE_" .. locale] = true', locale)
    # Files after Generated.lua load into an empty table so each file's own strings can be compared per locale.
    load_strings = lua.eval('''function(source, name)
        local merged = addon.L
        if merged then addon.L = {} end
        assert(loadstring(source, name))("Orbit_Portal", addon)
        local own = addon.L
        if merged then
            for key, value in pairs(own) do merged[key] = value end
            addon.L = merged
        end
        return own
    end''')
    written[locale] = {path.name: dict(load_strings(path.read_text(encoding="utf-8"), path.name).items())
                       for path in localization}
    for key in keys:
        assert isinstance(lua.globals().addon.L[key], str), (locale, key)
    strings[locale] = dict(lua.globals().addon.L.items())
    lua.eval("function(source) assert(loadstring(source))('Orbit_Portal', addon) end")(fonts.read_text(encoding="utf-8"))
    face, paths = FONT_FACES.get(locale, ""), lua.globals().addon.PortalFonts.Path
    faces = {"UI": f"OrbitSansCondensedUI{face}-ExtraBold.ttf", "Chat": f"OrbitSansCondensedChat{face}-Bold.ttf"}
    for kind, name in faces.items():
        assert paths[kind] == FONT_DIRECTORY + name and (ROOT / "Assets/Fonts" / name).is_file(), (locale, kind)
for alias, target in LOCALE_ALIASES.items():
    assert strings[alias] == strings[target], f"{alias} must show {target} strings"
for name in written["enUS"]:
    distinct = {tuple(sorted(written[locale][name].items())) for locale in LOCALES}
    assert len(distinct) == len(LOCALES), f"{name}: a locale resolves to another locale's strings"
print(f"PASS: Lua 5.1 compilation, {len(keys)} referenced localization keys and locale fonts across nine locales"
      f" plus {'/'.join(LOCALE_ALIASES)}")
