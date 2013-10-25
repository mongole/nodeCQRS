Logfiles to support JavaScript -> CoffeScript migration
====

steps to reset on every try:

 * stop node servers (host & domain)
 * in redis-cli:
  * FLUSHDB
  * keys * (to check it's empty)
 * restart servers
 * reload page in browser.

to test all the possible steps:

 * add: item 1
 * edit to: edited item 1
 * delete.

check the logs for equality.

automate this stuff!