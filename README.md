# Lexical UUID

Lexicographically-sortable universally unique identifier generation. Designed to solve the problem discussed 
[here](https://www.percona.com/blog/uuids-are-popular-but-bad-for-performance-lets-discuss/)

# v1

They are a modified UUID version 7 that uses nanosecond-precision timestamps. This kind of UUID was 
proposed in the first draft-peabody-dispatch-new-uuid-format, but then discarded from the specification.

The suggested implementation was as follows:
- The first 36 bits are dedicated to the Unix Timestamp: seconds since 1st January 1970 (unixts)
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The 4 Version bits conform to the UUID standard (ver).
- The next 12 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 2 bits are dedicated to the Variant (var).
- The next 14 bits are dedicated to providing sub-second encoding for the Nanosecond precision (nsec).
- The next 8 bits are dedicated a monotonic clock sequence counter (seq).
- The last 40 bits are filled out with random data to pad the length and provide uniqueness (rand).

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                            unixts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|unixts |         nsec          |  ver  |         nsec          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|var|             nsec          |      seq      |     rand      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

# v2

This version significantly deviates from UUID standards:
- Dedicate 32 bits to the timestamp in seconds and adjust the start to a more recent date, January 1st 
  2020. (Inspired by [KSUID](https://github.com/segmentio/ksuid))
- Dedicate 20 bits in total to the microsecond precision, represented by the specific number of microseconds.
- No version bits
- No variant bits
- Dedicate 68 bits to the random component.

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             adjts                             |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                 µsec                  |      seq      | rand  |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             rand                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

I prefer to use this version of Lexical UUID in my programs.
- I do not need strict UUID compatibility: Percona Server can still store and retrieve Lexical UUID 
  v2 with `UUID_TO_BIN()` and `BIN_TO_UUID()`, it does not matter to me if these are official UUID versions.
- I do not generate more than 255 of these per microsecond: the rate at which Lexical UUID v2 are generated 
  in my programs is not so high, to the point that the `seq` may even be superfluous.
