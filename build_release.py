"""Build a CodXe-ready Bot Warfare release archive."""

from pathlib import Path
import re
from zipfile import ZIP_DEFLATED, ZipFile


ARCHIVE_PREFIX = "iw4bw"
SOURCE_DIRS = ("maps", "scriptdata", "scripts")
MOD_ROOT = Path("_codxe/mods/bot_warfare")
VERSION_PATTERN = re.compile(r'level\.bw_version\s*=\s*"([^"]+)"')


def main() -> None:
    repo_root = Path(__file__).resolve().parent
    version_file = repo_root / "maps/mp/bots/_bot.gsc"
    match = VERSION_PATTERN.search(version_file.read_text(encoding="utf-8"))

    if match is None:
        raise RuntimeError(f"Could not find level.bw_version in {version_file}")

    archive_path = repo_root / f"{ARCHIVE_PREFIX}-{match.group(1)}.zip"

    with ZipFile(archive_path, "w", ZIP_DEFLATED) as archive:
        archive.writestr(
            "_codxe/codxe.json",
            '{\n  "active_mod": "bot_warfare"\n}\n',
        )

        for source_name in SOURCE_DIRS:
            source_dir = repo_root / source_name

            if not source_dir.is_dir():
                raise FileNotFoundError(f"Missing source directory: {source_dir}")

            for source_path in sorted(source_dir.rglob("*")):
                archive_path_in_zip = MOD_ROOT / source_path.relative_to(repo_root)

                if source_path.is_dir():
                    archive.writestr(archive_path_in_zip.as_posix() + "/", b"")
                else:
                    archive.write(source_path, archive_path_in_zip.as_posix())

    print(f"Created {archive_path.name}")


if __name__ == "__main__":
    main()
