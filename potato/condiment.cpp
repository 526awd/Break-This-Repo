// condiment.cpp - a condiment for your (possibly sprouted) potato
// All decided at compile time; runtime output is deterministic.
#ifndef CONDIMENT_NAME
#define CONDIMENT_NAME "unknown condiment"
#endif
#include <iostream>
using namespace std;
int main() {
  cout << "This is " CONDIMENT_NAME << "." << endl;
#ifdef CONDIMENT_EXPIRED
  static const char EXPIRED_MARK[] = "The " CONDIMENT_NAME " is expired.";
  cout << EXPIRED_MARK << endl;
#endif
#ifndef CONDIMENT_DELICIOUS
  static const char NOT_DELICIOUS_MARK[] =
      "The " CONDIMENT_NAME " is not delicious.";
  cout << NOT_DELICIOUS_MARK << endl;
#endif
  return 0;
}
