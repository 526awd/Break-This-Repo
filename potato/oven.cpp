#include <cstdio>
#include <cstring>
#include <iostream>
#include <string>
using namespace std;

static string shell_quote(const string &value) {
  string quoted = "'";
  for (char c : value) {
    if (c == '\'')
      quoted += "'\\''";
    else
      quoted += c;
  }
  return quoted + "'";
}

static string run_bin(const string &directory, const char *name) {
  string cmd = shell_quote(directory + "/" + name);
  string out;
  char buf[256];
  FILE *f = popen(cmd.c_str(), "r");
  if (!f)
    return "";
  while (fgets(buf, sizeof buf, f))
    out += buf;
  if (pclose(f) != 0)
    return "";
  return out;
}

static string executable_directory(const char *argv0) {
  string path(argv0);
  string::size_type slash = path.find_last_of("/");
  return slash == string::npos ? "." : path.substr(0, slash);
}

int main(int argc, char *argv[]) {
  const string directory = executable_directory(argv[0]);

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

  string potato_out = run_bin(directory, "potato");
  if (potato_out.find("sprout") != string::npos) {
    bad = true;
  }

  for (int i = 2; i < argc; i++) {
    string out = run_bin(directory, argv[i]);
    if (out.find("expired") != string::npos ||
        out.find("not delicious") != string::npos) {
      bad = true;
    }
  }

  if (bad) {
    cout << "Fatal error! how could the potato be not delicious?" << endl;
  } else {
    cout << "this is a cooked potato";
    if (argc > 2) {
      cout << " with";
      for (int i = 2; i < argc; i++) {
        cout << (i == 2 ? " " : ", ") << argv[i];
      }
    }
    cout << "." << endl;
    cout << "of course the potato is delicious" << endl;
  }
  return 0;
}
