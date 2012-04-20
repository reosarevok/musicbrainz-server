Installing MusicBrainz Server
=============================

The easiest method of installing a local MusicBrainz Server is to download the 
[pre-configured virtual machine](http://musicbrainz.org/doc/MusicBrainz_Server/Setup).

If you want to manually set up MusicBrainz Server from source, read on!

Prerequisites
-------------

1.  A Unix based operating system

    The MusicBrainz development team uses a mix of Ubuntu and Debian, but Mac OS
    X will work just fine, if you're prepared to potentially jump through some
    hoops. If you are running Windows we recommend you set up a Ubuntu virtual
    machine.

    **This document will assume you are using Ubuntu for its instructions.**

2.  Perl (at least version 5.10.1)

    Perl comes bundled with most Linux operating systems, you can check your
    installed version of Perl with:

        perl -v

3.  PostgreSQL (at least version 8.4)

    PostgreSQL is required, along with its development libraries. To install
    using packages run the following, replacing 8.x with the latest version.

        sudo apt-get install postgresql-8.x postgresql-server-dev-8.x postgresql-contrib

    Alternatively, you may compile PostgreSQL from source, but then make sure to
    also compile the cube extension found in contrib/cube. The database import
    script will take care of installing that extension into the database when it
    creates the database for you.

4.  Git

    The MusicBrainz development team uses Git for their DVCS. To install Git,
    run the following:

        sudo apt-get install git-core


5.  Memcached

    By default the MusicBrainz server requires a Memcached server running on the
    same server with default settings. You can change the memcached server name
    and port or configure other datastores in lib/DBDefs.pm.


Server configuration
--------------------

1.  Download the source code.

        git clone git://git.musicbrainz.org/musicbrainz-server.git
        cd musicbrainz-server

2.  Modify the server configuration file.

        cp lib/DBDefs.pm.default lib/DBDefs.pm

    Fill in the appropriate values for `MB_SERVER_ROOT` and `WEB_SERVER`.

    Determine what type of server this will be and set `REPLICATION_TYPE` accordingly:

    1.  `RT_SLAVE` (mirror server)

        A mirror server will always be in sync with the master database at
        http://musicbrainz.org by way of an hourly replication packet. Mirror
        servers do not allow any local editing. After the initial data import, the
        only changes allowed will be to load the next replication packet in turn.

        Mirror servers will have their WikiDocs automatically kept up to date.

        If you are not setting up a mirror server for development purposes, make
        sure to set `DB_STAGING_SERVER` to 0.

    2.  `RT_STANDALONE`

        A stand alone server is recommended if you are setting up a server for
        development purposes. They do not accept the replication packets and will
        require manually importing a new database dump in order to bring it up to
        date with the master database. Local editing is available, but keep in
        mind that none of your changes will be pushed up to http://musicbrainz.org.

        Stand alone servers will need to manually download and update their
        WikiDoc transclusion table:

            wget -O root/static/wikidocs/index.txt http://musicbrainz.org/static/wikidocs/index.txt


Installing Perl dependencies
----------------------------

The fundamental thing that needs to happen here is all the dependency Perl
modules get installed, somewhere where your server can find them. There are many
ways to make this happen, and the best choice will be very
site-dependent. MusicBrainz ships with support for Carton, a Perl package
manager, which will allow you to have the exact same dependencies as our
production servers. Carton also manages everything for you, and lets you avoid
polluting your system installation with these dependencies.

Below outlines how to setup MusicBrainz server with Carton.


1.  Prerequisities

    Before you get started you will actually need to have Carton installed as
    MusicBrainz does not yet ship with an executable. There are also a few
    development headers that will be needed when installing dependencies. Run
    the following steps as a normal user on your system.

        sudo apt-get install libxml2-dev libpq-dev libexpat1-dev libdb-dev memcached
        sudo cpan Carton

    NOTE: This installs Carton at the system level, if you prefer to install
    this in your home directory, use [local::lib](http://search.cpan.org/perldoc?local::lib).

2.  Install dependencies

    To install the dependencies for MusicBrainz server, first make sure you are
    in the MusicBrainz source code directory and run the following:

        carton install --deployment

    Note that if you've previously used this command in the musicbrainz folder it
    will not always upgrade all packages to their correct version.  If you're
    having trouble running musicbrainz, run "rm -rf local" in the musicbrainz
    directory to remove all packages previously installed by carton, and then run
    the above step again.


Creating the database
---------------------

1.  Install PostgreSQL Extensions

    Before you start, you need to install the PostgreSQL Extensions on your
    database server. To build the musicbrainz_unaccent extension run these
    commands:

        cd postgresql-musicbrainz-unaccent
        make
        sudo make install
        cd ..

    To build our collate extension you will need libicu and it's development
    files, to install these run:

        sudo apt-get install libicu-dev

    With libicu installed, you can build and install the collate extension by
    running:

        cd postgresql-musicbrainz-collate
        make
        sudo make install
        cd ..

    Note: If you are using Ubuntu 11.10, the collate extension currently does
    not work with gcc 4.6 and needs to be built with an older version such as
    gcc 4.4. To do this, run the following:

        sudo apt-get install gcc-4.4
        cd postgresql-musicbrainz-collate
        CC=gcc-4.4 make -e
        sudo make install
        cd ..


2.  Setup PostgreSQL authentication

    For normal operation, the server only needs to connect from one or two OS
    users (whoever your web server / crontabs run as), to one database (the
    MusicBrainz Database), as one PostgreSQL user. The PostgreSQL database name
    and user name are given in DBDefs.pm (look for the `READWRITE` key).  For
    example, if you run your web server and crontabs as "www-user", the
    following configuration recipe may prove useful:

        # in pg_hba.conf (Note: The order of lines is important!):
        local    musicbrainz_db    musicbrainz    ident    mb_map

        # in pg_ident.conf:
        mb_map    www-user    musicbrainz

    Alternatively, if you are running a server for development purposes and
    don't require any special access permissions, the following configuration in
    pg_hba.conf will suffice (make sure to insert this line before any other
    permissions):

        local   all    all    trust


3.  Create the database

    You have two options when it comes to the database. You can either opt for a
    clean database with just the schema (useful for developers with limited disk
    space), or you can import a full database dump.

    1.  Use a clean database

        To use a clean database, all you need to do is run:

            carton exec ./admin/InitDb.pl -- --createdb --clean

    2.  Import a database dump

        Our database dumps are provided twice a week and can be downloaded from
        ftp://ftp.musicbrainz.org/pub/musicbrainz/data/fullexport/

        To get going, you need at least the mbdump.tar.bz2,
        mbdump-editor.tar.bz2 and mbdump-derived.tar.bz2 archives, but you can
        grab whichever dumps suit your needs. Assuming the dumps have been
        downloaded to /tmp/dumps/ you can import them with:

            carton exec ./admin/InitDb.pl -- --createdb --import /tmp/dumps/mbdump*.tar.bz2 --echo

        `--echo` just gives us a bit more feedback in case this goes wrong, you
        may leave it off. Remember to change the paths to your mbdump*.tar.bz2
        files, if they are not in /tmp/dumps/.


    NOTE: on a fresh postgresql install you may see the following error:

        CreateFunctions.sql:33: ERROR:  language "plpgsql" does not exist

    To resolve that login to postgresql with the "postgres" user (or any other
    postgresql user with SUPERUSER privileges) and load the "plpgsql" language
    into the database with the following command:

        postgres=# CREATE LANGUAGE plpgsql;


Starting the server
------------------

You should now have everything ready to run the development server!

The development server is a lightweight HTTP server that gives good debug
output and is much more convenient than having to set up a standalone
server. Just run:

    carton exec -- plackup -Ilib -r

Visiting http://your.machines.ip.address:5000 should now present you with
your own running instance of the MusicBrainz Server.

Troubleshooting
---------------

If you have any difficulties, please feel free to contact ocharles or warp
in #musicbrainz-devel on irc.freenode.net, or email the developer mailing
list at musicbrainz-devel [at] lists.musicbrainz.org.

Please report any issues on our [bug tracker](http://tickets.musicbrainz.org).

Good luck, and happy hacking!
