
let 
 # pkgs = import ( fetchTarball "https://github.com/NixOS/nixpkgs/archive/34beeb7d518bdfe4d77251e9391fb58e05f7d412.tar.gz") {};
  pkgs = import <nixpkgs>{};
  piensa =  import (fetchTarball https://github.com/piensa/nur-packages/archive/1d0d8c3f9e19ac7fe9bf0eefa4419e6721736a9c.tar.gz) {};
  pg = pkgs.postgresql_11.withPackages(ps: [ps.postgis]);
  puertico-init = pkgs.writeShellScriptBin "puertico-init" ''
    initdb -D $PGDATA --no-locale --encoding=UTF8 --auth=trust --auth-host=trust 
    pg_ctl -D $PGDATA -l $PGDATA/server.log start -w
    createuser puertico
    createdb puertico -O puertico
    psql puertico -c "CREATE EXTENSION postgis;"
    psql puertico -c "CREATE EXTENSION postgis_topology;"
    psql puertico -c "CREATE EXTENSION hstore;"
  '';
  puertico-start = pkgs.writeShellScriptBin "puertico-start" ''
    pg_ctl -D $PGDATA -l $PGDATA/server.log start -w
  '';
  puertico-tegola = pkgs.writeShellScriptBin "puertico-tegola" ''
    tegola serve --config=tegola.toml
  '';
  puertico-cache = pkgs.writeShellScriptBin "puertico-cache" ''
    tegola cache seed --config=tegola.toml --bounds "-74.855518, 11.011886, -74.839897, 11.027220" --min-zoom 17 --max-zoom 22 --overwrite
  '';
  puertico-stop = pkgs.writeShellScriptBin "puertico-stop" ''
    pg_ctl stop
  '';
  puertico-loadworld = pkgs.writeShellScriptBin "puertico-loadworld" ''
   sh ${piensa.puertico-osm}/natural_earth.sh
   sh ${piensa.puertico-osm}/osm_land.sh
  '';
  colombia = pkgs.fetchurl {
     url = https://download.geofabrik.de/south-america/colombia-190301.osm.pbf;
     sha256 = "1170pqz2bhfq2msdylf9i1z53d1gyshipd4h6zf2i9wyxb7gz3l0";
  };
  puertico-createuninorte = pkgs.writeShellScriptBin "puertico-createuninorte" ''
    osmconvert ${colombia} -B=uninorte.poly  -o=uninorte.pbf
  '';
  puertico-convertuninorte = pkgs.writeShellScriptBin "puertico-convertuninorte" ''
    osmconvert uninorte.osm -B=uninorte.poly  -o=uninorte.pbf
  '';
  puertico-loaduninorte = pkgs.writeShellScriptBin "puertico-loaduninorte" ''
    imposm import -connection postgis://puertico:puertico@localhost/puertico -mapping imposm3.json -read uninorte.pbf -write -overwritecache -srid 4326
    imposm  import -connection postgis://puertico:puertico@localhost/puertico -mapping imposm3.json -deployproduction -srid 4326
    psql puertico -a -f  ${piensa.puertico-osm}/postgis_helpers.sql
#    psql puertico -a -f  ${piensa.puertico-osm}/postgis_index.sql
  '';
in pkgs.stdenv.mkDerivation rec {
   name = "hola";

   src = builtins.filterSource (p: t: pkgs.lib.cleanSourceFilter p t && baseNameOf p != "data") ./.;

   buildInputs = with pkgs; [
     pg
     minio mc
     curl unzip gdal less
     osmctools
   ] ++ [
    piensa.tegola
    piensa.imposm
    piensa.puertico-osm
#    piensa.kepler
#    piensa.fresco
    piensa.colombia

    puertico-init
    puertico-start
    puertico-tegola
    puertico-cache
    puertico-stop
    puertico-loadworld
    puertico-loaduninorte
    puertico-createuninorte
   ];
  shellHooks = ''
     export PGDATA=$PWD/data;
  '';
}
