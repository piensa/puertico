
let 
  pkgs = import ( fetchTarball "https://github.com/NixOS/nixpkgs/archive/34beeb7d518bdfe4d77251e9391fb58e05f7d412.tar.gz") {};
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
    tegola serve --config=${piensa.puertico-osm}/tegola.toml
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
  puertico-loadcolombia = pkgs.writeShellScriptBin "puertico-loadcolombia" ''
    echo ${piensa.colombia}
    imposm import -connection postgis://puertico:puertico@localhost/puertico -mapping ${piensa.puertico-osm}/imposm3.json -read ${colombia} -write -overwritecache
    imposm  import -connection postgis://puertico:puertico@localhost/puertico -mapping ${piensa.puertico-osm}/imposm3.json -deployproduction 
    psql puertico -a -f  ${piensa.puertico-osm}/postgis_helpers.sql
    psql puertico -a -f  ${piensa.puertico-osm}/postgis_index.sql
  '';
in pkgs.stdenv.mkDerivation rec {
   name = "hola";

   src = builtins.filterSource (p: t: pkgs.lib.cleanSourceFilter p t && baseNameOf p != "data") ./.;

   buildInputs = with pkgs; [
     pg
     minio mc
     curl unzip gdal less
   ] ++ [
    piensa.hydra
    piensa.keto
    piensa.oathkeeper
    piensa.tegola
    piensa.imposm
    piensa.puertico-osm
#    piensa.kepler
#    piensa.fresco
    piensa.colombia

    puertico-init
    puertico-start
    puertico-tegola
    puertico-stop
    puertico-loadworld
    puertico-loadcolombia
   ];
  shellHooks = ''
     export PGDATA=$PWD/data;
  '';
}
