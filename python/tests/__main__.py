import os
import site
import sys
import inspect

print(f'version: {sys.version}')
print(f'version info: {sys.version_info}')
print(f'cwd: {os.getcwd()}')
print(f'site-packages folder: {site.getsitepackages()}')

print('\nsys path:')
for entry in sys.path:
    print(entry)

from libgreet.greeter import get_greeting

print(f'\nFirst party dep location: {inspect.getfile(get_greeting)}')
print('First party calling: ' + get_greeting('Matt'))

import django

print(f'\nDjango location: {django.__file__}')
print(f'Django version: {django.__version__}')

import logger

print(f'\nLogger library (not in relative package): {logger.__file__}')
logger.l("Hello from logger!")
