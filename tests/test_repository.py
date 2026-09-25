import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class RepositoryTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='setup-publication-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.env = {key: value for key, value in os.environ.items() if not key.startswith('GIT_')}
        self.env.update(HOME=str(self.root), GIT_CONFIG_SYSTEM=os.devnull, GIT_CONFIG_GLOBAL=os.devnull)
        names = ['config/repository-files.txt', 'scripts/check-repository.py', 'scripts/check-format.py']
        for name in names:
            path = self.root / name
            path.parent.mkdir(parents=True, exist_ok=True)
            if name.startswith('scripts/'):
                shutil.copy2(ROOT / name, path)
        (self.root / names[0]).write_text('\n'.join(names) + '\n')
        self.git('init', '-q')
        self.git('add', '--', *names)

    def git(self, *args):
        return subprocess.run(['git', *args], cwd=self.root, env=self.env,
                              capture_output=True, text=True, check=True)

    def run_script(self, name, *args):
        return subprocess.run([sys.executable, str(self.root / 'scripts' / name), *args],
                              cwd=self.root, env=self.env, capture_output=True, text=True)

    def test_finder_metadata_is_ignored_but_never_published(self):
        (self.root / 'config/.DS_Store').write_bytes(b'\x80finder metadata')
        result = self.run_script('check-format.py')
        self.assertEqual(result.returncode, 0, result.stderr)
        result = self.run_script('check-repository.py', '--archive', 'dist/setup.tar.gz')
        self.assertEqual(result.returncode, 0, result.stderr)
        with tarfile.open(self.root / 'dist/setup.tar.gz') as archive:
            expected = (self.root / 'config/repository-files.txt').read_text().splitlines()
            self.assertEqual(set(archive.getnames()), set(expected))
            for item in archive.getmembers():
                self.assertTrue(item.isfile())
                self.assertEqual((item.uid, item.gid, item.mtime), (0, 0, 0))
                self.assertFalse(item.pax_headers)
        # Even ignored Finder metadata is rejected if it was tracked by mistake.
        self.git('add', '--', 'config/.DS_Store')
        result = self.run_script('check-repository.py')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Publication boundary drift', result.stderr)

    def test_unknown_files_missing_files_and_symlinks_still_fail(self):
        extra = self.root / 'config/private.txt'
        extra.write_text('must never publish\n')
        result = self.run_script('check-repository.py')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Unreviewed publication files', result.stderr)
        extra.unlink()
        target = self.root / 'scripts/check-format.py'
        target.unlink()
        result = self.run_script('check-repository.py')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing or symlinked publication files', result.stderr)
        self.assertIn('scripts/check-format.py', result.stderr)
        target.symlink_to(ROOT / 'scripts/check-format.py')
        result = self.run_script('check-repository.py')
        self.assertNotEqual(result.returncode, 0)

    def test_shared_copy_requires_independent_git_boundary(self):
        shutil.rmtree(self.root / '.git')
        result = self.run_script('check-repository.py')
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('independent Git checkout', result.stderr)


if __name__ == '__main__':
    unittest.main()
