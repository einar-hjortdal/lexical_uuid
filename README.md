# LUUID: Lexical Universally Unique Identifier

Optimized for databases

## v1

- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 4 bits are dedicated to the version (ver).
- The next 26 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 8 bits are dedicated a monotonic clock sequence counter (seq).
- The last 42 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|             nsec          |      seq      |       rand        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## v2

This version is the same as the v1 but it does not contain `seq` bits.
The lack of monotonic clock sequence allows generation without a generator.

- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 4 bits are dedicated to the version (ver).
- The next 26 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The last 50 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|             nsec          |               rand                |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

## Utility functions

This module also exports some utility functions for working with LUUID.
- add_hyphens