
import imgmine.img_dedup.scan_check {
    scan_check
}

"Run the module `imgmine.img_dedup`."
shared void run() {
    value command = process.arguments.first;
    value args = process.arguments.rest;

    switch (command)
    case ("scan-check")
    {
        scan_check(args);
    }
    else
    {
        mainHelp();
    }
}

void mainHelp()
{
    print("    img-dedup <command> <args*>\n");
    print("  Available commands:");
    print("    * scan-check");
}