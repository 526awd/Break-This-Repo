#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>
using namespace std;

static string run_bin(const char *name) {
  string cmd = "./" + string(name);
  string out;
  char buf[256];
  FILE *f = popen(cmd.c_str(), "r");
  if (!f)
    return "";
  while (fgets(buf, sizeof buf, f))
    out += buf;
  pclose(f);
  return out;
}

int main(int argc, char *argv[]) {
  if (argc == 1) {
#ifdef OVEN_BROKEN
    static const char STATE[] = "oven is broken";
#else
    static const char STATE[] = "oven is working";
#endif
    cout << STATE << endl;
    return 0;
  }

  if (strcmp(argv[1], "potato") != 0) {
    cout << "why did you put the condiment in the oven first? now they've all "
            "spilled you stupid."
         << endl;
    return 0;
  }

#ifdef OVEN_BROKEN
  cout << "nothing happens when you turn on the oven." << endl;
  return 0;
#endif

  bool bad = false;

  string potato_out = run_bin("potato");
  if (potato_out.find("sprout") != string::npos) {
    bad = true;
  }

  for (int i = 2; i < argc; i++) {
    string out = run_bin(argv[i]);
    if (out.find("expired") != string::npos ||
        out.find("not delicious") != string::npos) {
      bad = true;
    }
  }

  if (bad) {
    cout << "Fatal error! how could the potato be not delicious?" << endl;
  } else {
    cout << "of course the potato is delicious" << endl;
  }
  return 0;
}
