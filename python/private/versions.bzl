"""Mirror of release info
"""

RELEASE_URL = "https://github.com/indygreg/python-build-standalone/releases/download/20211017"
RELEASE_DATE = "20211017T1616"

# The integrity hashes can be computed with
# shasum -b -a 384 [downloaded file] | awk '{ print $1 }' | xxd -r -p | base64
TOOL_VERSIONS = {
    "3.8.12": {
        "x86_64-apple-darwin": "sha384-es0kCVBb4q5xSC09lOw83TKXtR6qdt0NeU56JtK7Y5M5V784k9MM2q8leE3QWGH6",
        "x86_64-unknown-linux-gnu": "sha384-61BjosOUm+Uo2yDtkLcRqbSIAXIPiHKmvySGO2J/GSOHXkj5QBf4cwzrDuOWR0H2",
    },
    "3.9.7": {
        "x86_64-apple-darwin": "sha384-Ix7lxb+niRWcDCOsK1q53dAkOp0CIw40kM8wHv//WQs2O/il8SRJ60cP3R67fEnm",
        "aarch64-apple-darwin": "sha384-JSi3XZdHVZ+6DMybPYKgEYSQuBPpjXgBlj1uGqB9f/r3Wi6P0+CnYRG12TEzgcs6",
        "x86_64-unknown-linux-gnu": "sha384-+PNcmKXJ+ZiyKyZ2WR1XedDXJ05ujC2w9TdXl80vloYMqfIOpcVPOWUgre+btI+3",
    },
    "3.10.0": {
        "x86_64-apple-darwin": "sha384-eVTq704heZyKW6SB/DzarWB9S5bRH1LTQ4rFHzlKTE9jDjHDCBKyQhSgYy8a62lt",
        "aarch64-apple-darwin": "sha384-NbhxnZL0pBTKpzEfoCYWl6s2GYdfiI9HOSSHn1iCMZnIY6htt/KhzjwIgCP+Nj2u",
        "x86_64-unknown-linux-gnu": "sha384-iYJF9Y9o2Ain3YkuuF7ZGrGuJ+MyiD/xnrjJSap0TF2DR+I9XDx4stunNgx17gSn",
    },
}

MINOR_MAPPING = {
    "3.8": "3.8.12",
    "3.9": "3.9.7",
    "3.10": "3.10.0",
}
