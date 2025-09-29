
import requests
import os
import subprocess
import re

def get_latest_release_info(owner, repo):
    url = f"https://api.github.com/repos/{owner}/{repo}/releases/latest"
    response = requests.get(url)
    response.raise_for_status()
    release_info = response.json()
    return {
        "tag_name": release_info["tag_name"],
        "tarball_url": release_info["tarball_url"],
        "rev": release_info["tag_name"], # For releases, tag_name is usually the rev
    }

def calculate_hash(url):
    # Use nix-prefetch-url to get the sha256 hash
    # nix-prefetch-url --unpack <url>
    print(f"Calculating hash for {url}...")
    result = subprocess.run(
        ["nix-prefetch-url", "--unpack", url],
        capture_output=True,
        text=True,
        check=True
    )
    return result.stdout.strip()

def update_flake_nix(flake_path, new_version, new_rev, new_hash):
    with open(flake_path, 'r') as f:
        content = f.read()

    # Update version
    content = re.sub(r'version = "[^"]+";', f'version = "{new_version}";', content)
    # Update rev
    content = re.sub(r'rev = "[^"]+";', f'rev = "{new_rev}";', content)
    # Update hash
    content = re.sub(r'hash = "[^"]+";', f'hash = "{new_hash}";', content)

    with open(flake_path, 'w') as f:
        f.write(content)

    print(f"Updated {flake_path} with version={new_version}, rev={new_rev}, hash={new_hash}")

if __name__ == "__main__":
    owner = "nwiizo"
    repo = "ccswarm"
    flake_nix_path = os.path.join(os.path.dirname(__file__), "..", "flake.nix")

    print(f"Fetching latest release for {owner}/{repo}...")
    release = get_latest_release_info(owner, repo)
    print(f"Latest release tag: {release['tag_name']}")
    print(f"Tarball URL: {release['tarball_url']}")

    current_hash = calculate_hash(release['tarball_url'])
    print(f"Calculated hash: {current_hash}")

    update_flake_nix(flake_nix_path, release['tag_name'].lstrip('v'), release['rev'], current_hash)

    # TODO: Add git commit and PR creation logic here
