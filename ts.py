from datetime import datetime
from random import randrange

def gen_ts():
  """Usage: print(f'jobname-{utc_ts}utc-{salt}')"""
  utc_ts = datetime.utcnow().strftime('%Y%m%d-%H%M%S')
  salt = randrange(0x7fffffff)
  return utc_ts, salt
