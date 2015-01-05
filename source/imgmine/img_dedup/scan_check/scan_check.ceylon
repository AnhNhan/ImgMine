
import anhnhan.image.common {
    RGB
}
import anhnhan.image.processing {
    dhash,
    dhash_to_string
}

import ceylon.collection {
    LinkedList,
    group,
    HashMap
}
import ceylon.file {
    parsePath,
    Directory,
    Link,
    File,
    Nil
}

import imgmine.common {
    loadImage,
    BufferedImageView,
    resizeBufferedImageView
}

import java.lang {
    JString=String,
    Thread
}
import java.util.regex {
    Pattern
}

variable
Integer counter = 0;

variable
Integer total = 0;

shared
void scan_check(String[] args)
{
    if (is [] args)
    {
        print("You have to supply a directory!");
        return;
    }

    if (args.size > 1)
    {
        print("Too many args. scan-check only accepts a single argument.");
        return;
    }
    assert(nonempty args);

    value dirPath = parsePath(args.first.trimTrailing((char) => char in "\\/"));
    value dir = dirPath.resource;

    switch (dir)
    case (is Directory)
    {}
    case (is File)
    {
        print("``dirPath`` is a file, aborting.");
        return;
    }
    case (is Link)
    {
        print("``dirPath`` in a link, aborting.");
        return;
    }
    case (is Nil)
    {
        print("``dirPath`` does not exist, aborting.");
        return;
    }
    assert(is Directory dir);

    value pattern = Pattern.compile("\\.(jp[e]?g|png|bmp)$", Pattern.\iCASE_INSENSITIVE);
    value images = fishAllFiles(dir, (fileName) => pattern.matcher(JString(fileName)).find());

    print("Found ``images.size`` images. Processing now.");

    value threadCount = 4;
    value partitionSize = images.size / threadCount + 5;
    value partitioned = images*.string.partition(partitionSize);

    value map = HashMap<String, {Boolean*}>();

    print("Using ``threadCount`` threads, partition size of ``partitionSize``.");
    variable
    value activeThreads = 0;
    void reportBack({<String->{Boolean*}>*} result)
    {
        map.putAll(result);
        activeThreads--;
        print("\n  Finished a thread.");
    }
    void threadFails(Exception exc, String currentFile)
    {
        activeThreads--;
        print("\n  Thread failed (``className(exc)``: '``exc.message``') while processing ``currentFile``.");
    }
    void startProcessor([String+] files)
    {
        activeThreads++;

        value processor = HashProcessor(
            files,
            void (file)
            {
                process.write(".");
                counter++;
                total++;
            },
            reportBack,
            threadFails
        );
        processor.start();
    }

    for (_ in 0..threadCount)
    {
        value partition = partitioned.getFromFirst(_);
        if (exists partition)
        {
            startProcessor(partition);
        }
    }

    while (activeThreads > 0)
    {
        print("\n  Processed ``counter`` (total ``total``) images.");
        counter = 0;
        Thread.sleep(2000);
    }

    print("\n  Processed ``counter`` (total ``total``) images.");

    value grouped = group(map*.key, (String file) => map[file] else nothing);
    print("\n\nDone.\n");

    value duplicates = grouped.filter(({Boolean*}->[String+] element) => element.item.size > 1);
    for (hash->files in duplicates)
    {
        print("\n  ``dhash_to_string(hash)`` (" + formatInteger(dhashToInt(hash), 16).trimLeading('-'.equals) + ") [``files.size``]");
        for (file in files)
        {
            print("  - ``file``");
        }
    }
}

{File*} fishAllFiles(Directory dir, Boolean(String) pred)
{
    value files = LinkedList<File>();

    for (child in dir.children())
    {
        switch (child)
        case (is File)
        {
            if (pred(child.name))
            {
                files.add(child);
            }
        }
        case (is Directory)
        {
            files.addAll(fishAllFiles(child, pred));
        }
        case (is Link)
        {
            value linked = child.linkedResource;
            switch (linked)
            case (is File)
            {
                if (pred(linked.name))
                {
                    files.add(linked);
                }
            }
            case (is Directory)
            {
                files.addAll(fishAllFiles(linked, pred));
            }
            case (is Nil)
            {}
        }
    }

    return files;
}

Integer dhashToInt({Boolean*} hash)
{
    value addressableBits = 64;
    //assert(hash.size < addressableBits);
    variable
    Integer output = #0;

    for (index->bit in hash.indexed)
    {
        value offset = addressableBits - index;
        output = output.set(offset, bit);
    }

    return output;
}

class HashProcessor([String+] files, Anything(String) onEach, Anything({<String->{Boolean*}>*}) reportBack, Anything(Exception, String) reportTerminate)
        extends Thread()
{
    shared actual
    void run()
    {
        variable
        String current = "";
        try
        {
            value hashes = files.collect((String file)
                {
                    current = file;
                    value img = loadImage(file);
                    value hash = dhash<RGB, BufferedImageView>
                    {
                        convertToLuminosity = (rgb) => rgb.greyscale.r;
                        downscale = resizeBufferedImageView;
                    }(img);
                    onEach(file);
                    return file->hash;
                }
            );
            reportBack(hashes);
        }
        catch (Exception exc)
        {
            reportTerminate(exc, current);
        }
    }
}
