cdebug is tiny debug utility for C/Objective-C code

 * Functions are enabled/disabled by debug macro 'DEBUG'
 * Conditional log, assertion with log

See document on [Github] (http://youknowone.github.com/cdebug)

# How to setup
To take advantage of this feature, do one of below:
 * Insert #define DEBUG 1
 * Add compiler option -DDEBUG

To force disabling this function without eliminating 'DEBUG' macro, set NO\_DEBUG

# functions
## dprintf
dprintf is shallow wrapper for printf.

dprintf insert filename, line number, timestamp, newline by options

## dlog
dlog is dprintf with test.

dlog is triggered only if first parameter condition passes test.
For example:
 * #define LOG\_ERROR 3
 * #define LOG\_WARNING 2
 * #define LOG\_INFO 1
 * dlog(LOG\_WARNING, "Warn!");

This would be triggered only if DEBUG\_LOGLEVEL is lesser than DEBUG\_WARNING.

You can redefine test. See DEBUG\_LOGTEST in options.

## dassert
dassert is shallow wrapper for assert.

dassert is triggered only in debug mode. For release mode, use raw 'assert'.

## dassertlog
dassertlog is dassert + dprintf
When condition is false, both dprintf and dassert triggered.

# options
Define options if you don't like default
 1. DEBUG\_WITH\_FILE to enable \_\_FILE\_\_ macro (default: enabled)
 1. DEBUG\_WITH\_LINE to enable \_\_LINE\_\_ macro (default: enabled)
 1. DEBUG\_WITH\_TIME to enable runtime timestamp (default: enabled)
 1. DEBUG\_NEWLINE to enable newline insertion (default: enabled)
 1. DEBUG\_LOGLEVEL to define dlog trigger level (default: enabled)
 1. DEBUG\_LOGTEST(LV) to define dlog trigger test. (default: LV >= DEBUG\_LOGLEVEL)
 1. DEBUG\_ASSERT to enable real assert in dassert (default: enabled)
 1. DEBUG\_PRINTF to define printf function (default: printf in stdio.h)
 1. DEBUG\_USE\_NSLOG to enable automated NSLog flag for objective-c context (default: enabled)