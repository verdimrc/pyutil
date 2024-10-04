#!/usr/bin/env python3

# https://meta.discourse.org/t/stripping-outlook-safe-link-urls/258114/6

import urllib.parse
import sys

def decode_safelink(link):
    try:
        parsed = urllib.parse.urlparse(link)
        if parsed.netloc != 'nam11.safelinks.protection.outlook.com':
            return link
        query = urllib.parse.parse_qs(parsed.query)
        return query['url'][0]
    except:
        return link

if __name__ == '__main__':
    link = sys.argv[1]
    print(decode_safelink(link))
