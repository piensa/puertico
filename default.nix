
let 
 # pkgs = import ( fetchTarball "https://github.com/NixOS/nixpkgs/archive/34beeb7d518bdfe4d77251e9391fb58e05f7d412.tar.gz") {};
  pkgs = import <nixpkgs>{};
  piensa =  import (fetchTarball https://github.com/piensa/nur-packages/archive/1d0d8c3f9e19ac7fe9bf0eefa4419e6721736a9c.tar.gz) {};
  pg = pkgs.postgresql_11.withPackages(ps: [ps.postgis]);

  imposm-config = pkgs.writeText "imposm-config" ''
{
    "tags": {
        "load_all": true,
        "exclude": [
            "created_by",
            "source",
            "source:datetime"
        ]
    },
    "generalized_tables": {
        "water_areas_gen1": {
            "source": "water_areas",
            "sql_filter": "ST_Area(geometry)>50000.000000",
            "tolerance": 50.0
        },
        "water_areas_gen0": {
            "source": "water_areas_gen1",
            "sql_filter": "ST_Area(geometry)>500000.000000",
            "tolerance": 200.0
        },
        "transport_lines_gen0": {
            "source": "transport_lines_gen1",
            "sql_filter": null,
            "tolerance": 200.0
        },
        "transport_lines_gen1": {
            "source": "transport_lines",
            "sql_filter": "type IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') OR class IN('railway')",
            "tolerance": 50.0
        },
        "water_lines_gen0": {
            "source": "water_lines_gen1",
            "sql_filter": null,
            "tolerance": 200
        },
        "water_lines_gen1": {
            "source": "water_lines",
            "sql_filter": null,
            "tolerance": 50.0
        },
        "landuse_areas_gen1": {
            "source": "landuse_areas",
            "sql_filter": "ST_Area(geometry)>50000.000000",
            "tolerance": 50.0
        },
        "landuse_areas_gen0": {
            "source": "landuse_areas_gen1",
            "sql_filter": "ST_Area(geometry)>500000.000000",
            "tolerance": 200.0
        }
    },
    "tables": {
        "admin_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "integer",
                    "name": "admin_level",
                    "key": "admin_level"
                },
		{
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "polygon",
            "mapping": {
                "boundary": [
                    "administrative"
                ]
            }
        },
        "place_points": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "integer",
                    "name": "population",
                    "key": "population"
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "point",
            "mapping": {
                "place": [
                    "__any__"
                ]
            }
        },
        "landuse_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "pseudoarea",
                    "name": "area",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "polygon",
            "mappings": {
                "landuse": {
                    "mapping": {
                        "landuse": [
                            "__any__"
                        ]
                    }
                },
                "leisure": {
                    "mapping": {
                        "leisure": [
                            "__any__"
                        ]
                    }
                },
                "natural": {
                    "mapping": {
                        "natural": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "water_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "pseudoarea",
                    "name": "area",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "polygon",
            "mapping": {
                "waterway": [
                    "__any__"
                ],
                "landuse": [
                    "basin",
                    "reservoir"
                ],
                "natural": [
                    "water"
                ]
            }
        },
        "water_lines": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "linestring",
            "mapping": {
                "waterway": [
                    "__any__"
                ],
                "barrier": [
                    "ditch"
                ]
            }
        },
        "transport_points": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "ref",
                    "key": "ref"
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "point",
            "mappings": {
                "railway": {
                    "mapping": {
                        "railway": [
                            "__any__"
                        ]
                    }
                },
                "highway": {
                    "mapping": {
                        "highway": [
                            "__any__"
                        ]
                    }
                },
                "aeroway": {
                    "mapping": {
                        "aeroway": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "transport_lines": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "boolint",
                    "name": "tunnel",
                    "key": "tunnel"
                },
                {
                    "type": "boolint",
                    "name": "bridge",
                    "key": "bridge"
                },
                {
                    "type": "direction",
                    "name": "oneway",
                    "key": "oneway"
                },
                {
                    "type": "string",
                    "name": "ref",
                    "key": "ref"
                },
                {
                    "type": "wayzorder",
                    "name": "z_order",
                    "key": "layer"
                },
                {
                    "type": "string",
                    "name": "access",
                    "key": "access"
                },
                {
                    "type": "string",
                    "name": "service",
                    "key": "service"
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "linestring",
            "filters": {
                "exclude_tags": [
                    ["area", "yes"]
                ]
            },
            "mappings": {
		"railway": {
                    "mapping": {
                        "railway": [
                            "__any__"
			]
                    }
                },
                "highway": {
                    "mapping": {
                        "highway": [
                            "__any__"
 			]
                    }
                },
                "aeroway": {
                    "mapping": {
                        "aeroway": [
                            "__any__"
 			]
                    }
                }
            }
        },
        "transport_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "polygon",
            "mappings": {
                "rail": {
                    "mapping": {
                        "railway": [
                            "__any__"
                        ]
                    }
                },
                "highway": {
                    "mapping": {
                        "highway": [
                            "__any__"
                        ]
                    }
                },
                "aeroway": {
                    "mapping": {
                        "aeroway": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "amenity_points": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
		{
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "point",
            "mapping": {
                "amenity": [
                    "__any__"
                ]
            }
        },
        "amenity_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "polygon",
            "mapping": {
                "amenity": [
                    "__any__"
                ]
            }
        },
        "other_points": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "point",
            "mappings": {
                "barrier": {
                    "mapping": {
                        "barrier": [
                            "__any__"
                        ]
                    }
                },
                "historic": {
                    "mapping": {
                        "historic": [
                            "__any__"
                        ]
                    }
                },
                "man_made": {
                    "mapping": {
                        "man_made": [
                            "__any__"
                        ]
                    }
                },
                "power": {
                    "mapping": {
                        "power": [
                            "__any__"
                        ]
                    }
                },
                "military": {
                    "mapping": {
                        "military": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "other_lines": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "linestring",
            "mappings": {
                "barrier": {
                    "mapping": {
                        "barrier": [
                            "__any__"
                        ]
                    }
                },
                "historic": {
                    "mapping": {
                        "historic": [
                            "__any__"
                        ]
                    }
                },
                "man_made": {
                    "mapping": {
                        "man_made": [
                            "__any__"
                        ]
                    }
                },
                "power": {
                    "mapping": {
                        "power": [
                            "__any__"
                        ]
                    }
                },
                "military": {
                    "mapping": {
                        "military": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "other_areas": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type": "pseudoarea",
                    "name": "area",
                    "key": null
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                },
                {
                    "type": "mapping_key",
                    "name": "class",
                    "key": null
                }
            ],
            "type": "polygon",
            "mappings": {
                "barrier": {
                    "mapping": {
                        "barrier": [
                            "__any__"
                        ]
                    }
                },
                "historic": {
                    "mapping": {
                        "historic": [
                            "__any__"
                        ]
                    }
                },
                "man_made": {
                    "mapping": {
                        "man_made": [
                            "__any__"
                        ]
                    }
                },
                "power": {
                    "mapping": {
                        "power": [
                            "__any__"
                        ]
                    }
                },
                "military": {
                    "mapping": {
                        "military": [
                            "__any__"
                        ]
                    }
                }
            }
        },
        "buildings": {
            "fields": [
                {
                    "type": "id",
                    "name": "osm_id",
                    "key": null
                },
                {
                    "type": "geometry",
                    "name": "geometry",
                    "key": null
                },
                {
                    "type": "string",
                    "name": "name",
                    "key": "name"
                },
                {
                    "type": "mapping_value",
                    "name": "type",
                    "key": null
                },
                {
                    "type":"string",
                    "name":"height",
                    "key": "height"
                },
                {
                    "type": "hstore_tags",
                    "name": "tags",
                    "key": null
                }
            ],
            "type": "polygon",
            "mapping": {
                "building": [
                    "__any__"
                ]
            }
        }
    }
}
  '';
  tegola-config = pkgs.writeText "tegola.toml" ''
[webserver]
port = ":9090"
hostname = "localhost:9999"

# Tegola offers three tile caching strategies: "file", "redis", and "s3"
[cache]
type = "file"
basepath = "./var/cache"

#   OpenStreetMap (OSM)
[[providers]]
name = "osm"
type = "postgis"
host = "localhost"
port = 5432
database = "puertico"
user = "puertico"
password = ""
srid = 4326
max_connections = 10

	# Water
	[[providers.layers]]
	name = "water_areas"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type, area FROM osm_water_areas WHERE type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank', 'dock') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_areas_gen0"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type, area FROM osm_water_areas_gen0 WHERE type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 1000000000 AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_areas_gen0_6"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type, area FROM osm_water_areas_gen0 WHERE type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 100000000 AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_areas_gen1"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type, area FROM osm_water_areas_gen1 WHERE type IN ('water', 'pond', 'basin', 'canal', 'mill_pond', 'riverbank') AND area > 1000 AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_lines"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type FROM osm_water_lines WHERE type IN ('river', 'canal', 'stream', 'ditch', 'drain', 'dam') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_lines_gen0"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type FROM osm_water_lines_gen0 WHERE type IN ('river', 'canal') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "water_lines_gen1"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type FROM osm_water_lines_gen1 WHERE type IN ('river', 'canal', 'stream', 'ditch', 'drain', 'dam') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "admin_boundaries_8-12"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, admin_level, name, type FROM osm_admin_areas WHERE admin_level IN (1,2,3,4,5,6,7,8) AND geometry && !BBOX!"

	[[providers.layers]]
	name = "admin_boundaries_13-20"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, admin_level, name, type FROM osm_admin_areas WHERE admin_level IN (1,2,3,4,5,6,7,8,9,10) AND geometry && !BBOX!"

	# Land Use
	[[providers.layers]]
	name = "landuse_areas"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type, area FROM osm_landuse_areas WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "landuse_areas_gen0"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type, area FROM osm_landuse_areas_gen0 WHERE type IN ('forest','wood','nature reserve', 'nature_reserve', 'military') AND area > 1000000000 AND geometry && !BBOX!"

	[[providers.layers]]
	name = "landuse_areas_gen0_6"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type, area FROM osm_landuse_areas_gen0 WHERE type IN ('forest','wood','nature reserve', 'nature_reserve', 'military') AND area > 100000000 AND geometry && !BBOX!"

	[[providers.layers]]
	name = "landuse_areas_gen1"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type, area FROM osm_landuse_areas_gen1 WHERE geometry && !BBOX!"

	# Transport
	[[providers.layers]]
	name = "transport_points"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_transport_points WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_areas"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_transport_areas WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_lines_gen0"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, type, tunnel, bridge, ref FROM osm_transport_lines_gen0 WHERE type IN ('motorway','trunk','motorway_link','trunk_link','primary') AND tunnel = 0 AND bridge = 0  AND geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_lines_gen1"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, ref, class, type FROM osm_transport_lines_gen1 WHERE type IN ('motorway', 'trunk', 'primary', 'primary_link', 'secondary', 'motorway_link', 'trunk_link') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_lines_11-12"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, ref, class, type, tunnel, bridge, access, service FROM osm_transport_lines WHERE type IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'rail', 'taxiway', 'runway', 'apron') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_lines_13"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, ref, class, type, tunnel, bridge, access, service FROM osm_transport_lines WHERE type IN ('motorway', 'motorway_link', 'trunk', 'trunk_link', 'primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link', 'rail', 'residential', 'taxiway', 'runway', 'apron') AND geometry && !BBOX!"

	[[providers.layers]]
	name = "transport_lines_14-20"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, ref, class, type, tunnel, bridge, access, service FROM osm_transport_lines WHERE geometry && !BBOX!"

	# Amenities
	[[providers.layers]]
	name = "amenity_areas"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type FROM osm_amenity_areas WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "amenity_points"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, type FROM osm_amenity_points WHERE geometry && !BBOX!"

	# Other (Man Made, Historic, Military, Power, Barrier etc)
	[[providers.layers]]
	name = "other_points"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_other_points WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "other_lines"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_other_lines WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "other_areas"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_other_areas WHERE geometry && !BBOX!"

	[[providers.layers]]
	name = "other_areas_filter"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, class, type FROM osm_other_areas WHERE area > 1000000 AND geometry && !BBOX!"

	# Buildings
	[[providers.layers]]
	name = "buildings"
	geometry_fieldname = "geometry"
	id_fieldname = "osm_id"
	sql = "SELECT ST_AsBinary(geometry) AS geometry, osm_id, name, nullif(as_numeric(height),-1) AS height, type FROM osm_buildings WHERE geometry && !BBOX!"


[[maps]]
name = "osm"
attribution = "OpenStreetMap" # map attribution
center = [-74.8485, 11.0206, 17.0] # optional center value. part of the TileJSON spec

	[[maps.layers]]
	name = "landuse_areas"
	provider_layer = "osm.landuse_areas"
	min_zoom = 16
	max_zoom = 22

	[[maps.layers]]
	name = "water_areas"
	provider_layer = "osm.water_areas"
	min_zoom = 16
	max_zoom = 22

	[[maps.layers]]
	name = "water_lines"
	provider_layer = "osm.water_lines"
	min_zoom = 16
	max_zoom = 22


	[[maps.layers]]
	name = "transport_lines"
	provider_layer = "osm.transport_lines_14-20"
	min_zoom = 16
	max_zoom = 22

	# Transport Areas
	[[maps.layers]]
	name = "transport_areas"
	provider_layer = "osm.transport_areas"
	min_zoom = 16
	max_zoom = 22

	# Transport Points
	[[maps.layers]]
	name = "transport_points"
	provider_layer = "osm.transport_points"
	min_zoom = 16
	max_zoom = 22

	# Amenity Areas
	[[maps.layers]]
	name = "amenity_areas"
	provider_layer = "osm.amenity_areas"
	min_zoom = 16
	max_zoom = 22

	# Amenity Points
	[[maps.layers]]
	name = "amenity_points"
	provider_layer = "osm.amenity_points"
	min_zoom = 16
	max_zoom = 22

	# Other Points
	[[maps.layers]]
	name = "other_points"
	provider_layer = "osm.other_points"
	min_zoom = 16
	max_zoom = 22

	# Other Lines
	[[maps.layers]]
	name = "other_lines"
	provider_layer = "osm.other_lines"
	min_zoom = 16
	max_zoom = 22

	[[maps.layers]]
	name = "other_areas"
	provider_layer = "osm.other_areas"
	min_zoom = 16
	max_zoom = 22

	# Buildings
	[[maps.layers]]
	name = "buildings"
	provider_layer = "osm.buildings"
	min_zoom = 16
	max_zoom = 22
  '';
  area-poly = pkgs.writeText "area.poly" ''
salida-0
1
        -74.85208511352539      11.027219456385142
        -74.85551834106445      11.025955764462422
        -74.8550033569336       11.01584603362195
        -74.84298706054688      11.011886294383482
        -74.83989715576172      11.015677535164972
        -74.8399829864502       11.020648199089703
        -74.85208511352539      11.027219456385142
END
END
  '';
  nginx-config = pkgs.writeText "nginx.conf" ''
  daemon            off;
  worker_processes  2;

  events {
    use           epoll;
    worker_connections  128;
  }

  error_log         error.log info;

  http {
    server_tokens off;
    charset       utf-8;

    access_log    access.log  combined;

    proxy_cache_path /x/puertico/var/nginx/ levels=1:2 keys_zone=my_zone:100m inactive=600m;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    server {
      server_name   localhost;
      listen        127.0.0.1:9999;

      error_page    500 502 503 504  /50x.html;

      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_cache my_zone;
      proxy_redirect     off;
 
      location      / {
        add_header X-Proxy-Cache $upstream_cache_status;
        root      /x/puertico/static;
      }

      location /capabilities {
        proxy_pass http://localhost:9090/capabilities;
      }

      location /maps {
        proxy_pass http://localhost:9090/maps;
      }

      location /tegola {
        proxy_pass http://localhost:9090/;
      }


    }
  }
  '';
  puertico-init = pkgs.writeShellScriptBin "puertico-init" ''
    initdb -D $PGDATA --no-locale --encoding=UTF8 --auth=trust --auth-host=trust 
    pg_ctl -D $PGDATA -l $PGDATA/server.log start -w
    createuser puertico
    createdb puertico -O puertico
    psql puertico -c "CREATE EXTENSION postgis;"
    psql puertico -c "CREATE EXTENSION postgis_topology;"
    psql puertico -c "CREATE EXTENSION hstore;"
  '';
  puertico-nginx = pkgs.writeShellScriptBin "puertico-nginx" ''
    nginx -c ${nginx-config} -p $PUERTICO_DATA
  '';
  puertico-start = pkgs.writeShellScriptBin "puertico-start" ''
    pg_ctl -D $PGDATA -l $PGDATA/server.log start -w
  '';
  puertico-tegola = pkgs.writeShellScriptBin "puertico-tegola" ''
    tegola serve --config=${tegola-config}
  '';
  puertico-cache = pkgs.writeShellScriptBin "puertico-cache" ''
    tegola cache seed --config=${tegola-config} --bounds "-74.855518, 11.011886, -74.839897, 11.027220" --min-zoom 17 --max-zoom 20 --overwrite
  '';
  puertico-stop = pkgs.writeShellScriptBin "puertico-stop" ''
    pg_ctl stop
  '';
  country-osm = pkgs.fetchurl {
     url = https://download.geofabrik.de/south-america/colombia-190301.osm.pbf;
     sha256 = "1170pqz2bhfq2msdylf9i1z53d1gyshipd4h6zf2i9wyxb7gz3l0";
  };
  puertico-createarea = pkgs.writeShellScriptBin "puertico-createarea" ''
    osmconvert ${country-osm} -B=${area-poly}  -o=$PUERTICO_DATA/area.pbf
  '';
  puertico-loadarea = pkgs.writeShellScriptBin "puertico-loadarea" ''
    imposm import -connection postgis://puertico:puertico@localhost/puertico -mapping ${imposm-config} -read $PUERTICO_DATA/area.pbf -write -overwritecache -srid 4326
    imposm  import -connection postgis://puertico:puertico@localhost/puertico -mapping ${imposm-config} -deployproduction -srid 4326
    psql puertico -a -f  ${piensa.puertico-osm}/postgis_helpers.sql
#    psql puertico -a -f  ${piensa.puertico-osm}/postgis_index.sql
  '';
in pkgs.stdenv.mkDerivation rec {
   name = "puertico";

   src = builtins.filterSource (p: t: pkgs.lib.cleanSourceFilter p t && baseNameOf p != "state") ./.;

   buildInputs = with pkgs; [
     pg
     minio mc
     curl unzip gdal less
     osmctools
   ] ++ [
    piensa.tegola
    piensa.imposm
    piensa.colombia
    nginx

    puertico-nginx
    puertico-init
    puertico-start
    puertico-tegola
    puertico-cache
    puertico-stop
    puertico-loadworld
    puertico-loadarea
    puertico-createarea
   ];
  shellHooks = ''
     export PUERTICO_DATA=$PWD/var
     mkdir -p $PUERTICO_DATA/logs
     export PGDATA=$PUERTICO_DATA/data
  '';
}
