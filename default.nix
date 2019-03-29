
let 
 # pkgs = import ( fetchTarball "https://github.com/NixOS/nixpkgs/archive/34beeb7d518bdfe4d77251e9391fb58e05f7d412.tar.gz") {};
  pkgs = import <nixpkgs>{};
  piensa =  import (fetchTarball https://github.com/piensa/nur-packages/archive/1d0d8c3f9e19ac7fe9bf0eefa4419e6721736a9c.tar.gz) {};
  pg = pkgs.postgresql_11.withPackages(ps: [ps.postgis]);
  hostName = "127.0.0.1:9999";
  tegolaPort = "9090";
  pwd = "/x/puertico";
  stateDir = "${pwd}/state";
  staticDir = "${pwd}/static";
  server_url = "http://${hostName}";

  index-html = pkgs.writeText "index-html" ''
     <!DOCTYPE html>
<html>
<head>
  <meta charset=utf-8 />
  <title>mobility</title>
  <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' />
  
  <style>
    body { margin:0; padding:0; }
    #map { position:absolute; top:0; bottom:0; width:100%; }
  </style>
  <script src='mapbox/v0.53.1/mapbox-gl.js'></script>
  <link href='mapbox/v0.53.1/mapbox-gl.css' rel='stylesheet' />
</head>
<body>
  <div id='map'></div>
  <script>
    var bounds = [[-74.86, 11.01], [-74.84, 11.03]];

  var map = new mapboxgl.Map({
      container: 'map',
      style: 'style.json',
      center: [-74.85, 11.02],
      zoom: 16,
      minZoom: 16,
      maxZoom: 24,
      maxBounds: bounds,
      bearing: -10,
      pitch: 0,
      hash: true
  });
   map.addControl(new mapboxgl.NavigationControl());
  </script>
</body>
</html>
  '';

  style-config = pkgs.writeText "style-config" ''
{
  "pitch": 0,
  "layers": [
    {
      "id": "background",
      "type": "background",
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "background-color": "rgba(186, 193, 203, 0)"
      }
    },
    {
      "id": "land",
      "type": "fill",
      "source": "osm",
      "source-layer": "land",
      "paint": {
        "fill-color": "rgba(198, 201, 193, 1)"
      }
    },
    {
      "id": "water_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "water_areas",
      "minzoom": 7,
      "maxzoom": 24,
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(27, 37, 52, 1)"
      }
    },
    {
      "minzoom": 3,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 7,
      "filter": [
        "all",
        [
          ">",
          "area",
          1000000000
        ]
      ],
      "type": "fill",
      "source": "osm",
      "id": "water_areas_z3",
      "paint": {
        "fill-color": "rgba(27, 37, 52, 1)"
      },
      "source-layer": "water_areas"
    },
    {
      "id": "landuse_areas",
      "type": "fill",
      "source": "osm",
      "source-layer": "landuse_areas",
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              "hospital",
              "rgba(189, 67, 67, 0.2)"
            ],
            [
              "school",
              "rgba(107, 73, 38, 0.15)"
            ],
            [
              "college",
              "rgba(107, 73, 38, 0.15)"
            ],
            [
              "education",
              "rgba(107, 73, 38, 0.15)"
            ],
            [
              "university",
              "rgba(107, 73, 38, 0.15)"
            ],
            [
              "residential",
              "rgba(153, 195, 150, 0.2)"
            ],
            [
              "grassland",
              "rgba(159, 173, 153, .5)"
            ],
            [
              "forest",
              "rgba(100, 179, 100, 0.09)"
            ],
            [
              "farm",
              "rgba(206, 212, 203, 1)"
            ],
            [
              "farmland",
              "rgba(206, 212, 203, 1)"
            ],
            [
              "orchard",
              "rgba(206, 212, 203, 1)"
            ],
            [
              "allotments",
              "rgba(206, 212, 203, 1)"
            ],
            [
              "garden",
              "rgba(206, 212, 203, 1)"
            ]
          ]
        }
      }
    },
    {
      "minzoom": 1,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "==",
          "type",
          "military"
        ]
      ],
      "type": "fill",
      "source": "osm",
      "id": "landuse_areas_military_overlay",
      "paint": {
        "fill-color": "rgba(178, 194, 157, 1)",
        "fill-pattern": "military-fill2"
      },
      "source-layer": "landuse_areas"
    },
    {
      "id": "landuse_areas_lines",
      "type": "line",
      "source": "osm",
      "source-layer": "landuse_areas",
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": {
          "property": "type",
          "type": "categorical",
          "default": "transparent",
          "stops": [
            [
              "hospital",
              "rgba(195, 32, 7, 0.5)"
            ],
            [
              "school",
              "rgba(105, 74, 35, 0.45)"
            ],
            [
              "college",
              "rgba(105, 74, 35, 0.45)"
            ],
            [
              "education",
              "rgba(105, 74, 35, 0.45)"
            ],
            [
              "university",
              "rgba(105, 74, 35, 0.45)"
            ]
          ]
        }
      }
    },
    {
      "id": "road_rail",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "rail"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "rgba(146, 143, 143, 1)",
        "line-width": {
          "base": 1.4,
          "stops": [
            [
              14,
              0.4
            ],
            [
              15,
              0.75
            ],
            [
              20,
              2
            ]
          ]
        }
      }
    },
    {
      "id": "road_railhatch",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "rail"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "miter"
      },
      "paint": {
        "line-color": "#928F8F",
        "line-dasharray": [
          0.2,
          8
        ],
        "line-width": {
          "base": 1.4,
          "stops": [
            [
              14.5,
              0
            ],
            [
              15,
              3
            ],
            [
              20,
              8
            ]
          ]
        }
      }
    },
    {
      "id": "road_service",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "track",
          "footway",
          "cycleway",
          "path",
          "service"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(181, 177, 169, 1)",
        "line-width": {
          "stops": [
            [
              15,
              1
            ],
            [
              16,
              4
            ],
            [
              20,
              11
            ]
          ]
        }
      }
    },
    {
      "id": "university_areas",
      "source": "osm",
      "type": "fill",
      "source-layer": "amenity_areas",
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "fill-color": "rgba(170, 223, 113, 1)"
      },
      "filter": [
        "all",
        [
          "in",
          "type",
          "university"
        ]
      ]
    },
    {
      "id": "road_service_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "track",
          "footway",
          "cycleway",
          "path",
          "service"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#ddd",
        "line-width": {
          "stops": [
            [
              15,
              1
            ],
            [
              16,
              6
            ],
            [
              20,
              20
            ]
          ]
        }
      }
    },
    {
      "id": "road_residential_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "residential"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              12,
              0.5
            ],
            [
              13,
              1
            ],
            [
              14,
              4
            ],
            [
              20,
              20
            ]
          ]
        }
      }
    },
    {
      "id": "road_residential",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "residential"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "round",
        "line-join": "round"
      },
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              13.5,
              0
            ],
            [
              14,
              2.5
            ],
            [
              20,
              18
            ]
          ]
        }
      }
    },
    {
      "id": "road_secondary_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "secondary",
          "tertiary"
        ]
      ],
      "layout": {
        "line-cap": "round",
        "line-join": "round",
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(129, 130, 124, 1)",
        "line-width": {
          "stops": [
            [
              8,
              1.5
            ],
            [
              10,
              2
            ],
            [
              20,
              13
            ]
          ]
        }
      }
    },
    {
      "id": "road_secondary",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "secondary",
          "tertiary"
        ]
      ],
      "layout": {
        "line-cap": "round",
        "line-join": "round",
        "visibility": "visible"
      },
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              6.5,
              0
            ],
            [
              8,
              0.5
            ],
            [
              10,
              1.5
            ],
            [
              20,
              9
            ]
          ]
        }
      }
    },
    {
      "id": "road_trunk_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "primary",
          "trunk",
          "trunk_link",
          "motorway_link",
          "primary_link"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-join": "round",
        "line-cap": "butt"
      },
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              5,
              0.4
            ],
            [
              6,
              0.7
            ],
            [
              7,
              1.5
            ],
            [
              10,
              2
            ],
            [
              20,
              14
            ]
          ]
        }
      }
    },
    {
      "id": "road_trunk",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "primary",
          "trunk",
          "trunk_link",
          "motorway_link",
          "primary_link"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-join": "round",
        "line-cap": "round"
      },
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              5,
              0
            ],
            [
              7,
              0.8
            ],
            [
              10,
              1.5
            ],
            [
              20,
              11
            ]
          ]
        }
      }
    },
    {
      "id": "road_motorway_case",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway"
        ]
      ],
      "layout": {
        "visibility": "visible",
        "line-cap": "butt",
        "line-join": "round"
      },
      "paint": {
        "line-color": "rgba(73, 74, 69, 1)",
        "line-width": {
          "stops": [
            [
              6,
              0.7
            ],
            [
              7,
              1.75
            ],
            [
              10,
              2.5
            ],
            [
              20,
              18
            ]
          ]
        }
      }
    },
    {
      "id": "road_motorway",
      "type": "line",
      "source": "osm",
      "source-layer": "transport_lines",
      "minzoom": 7,
      "filter": [
        "all",
        [
          "in",
          "type",
          "motorway"
        ]
      ],
      "layout": {
        "visibility": "visible"
      },
      "paint": {
        "line-color": "rgba(118, 121, 114, 1)",
        "line-width": {
          "stops": [
            [
              7,
              1
            ],
            [
              10,
              1.7
            ],
            [
              20,
              14
            ]
          ]
        }
      }
    },
    {
      "minzoom": 0,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 24,
      "filter": [
        "all",
        [
          "!has",
          "height"
        ]
      ],
      "type": "fill-extrusion",
      "source": "osm",
      "id": "building_tilt_na",
      "paint": {
        "fill-extrusion-color": "rgba(238, 165, 91, 1)",
        "fill-extrusion-height": 5,
        "fill-extrusion-base": 0,
        "fill-extrusion-opacity": 1
      },
      "source-layer": "buildings"
    },
    {
      "minzoom": 0,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 24,
      "filter": [
        "any",
        [
          "has",
          "height"
        ]
      ],
      "type": "fill-extrusion",
      "source": "osm",
      "id": "building_tilt",
      "paint": {
        "fill-extrusion-color": "rgba(249, 9, 38, 1)",
        "fill-extrusion-height": {
          "property": "height",
          "type": "identity"
        },
        "fill-extrusion-base": 0,
        "fill-extrusion-opacity": 1
      },
      "source-layer": "buildings"
    },
    {
      "minzoom": 4,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 7,
      "filter": [
        "all",
        [
          ">",
          "min_zoom",
          5
        ]
      ],
      "type": "line",
      "source": "osm",
      "id": "roads_motorway_z4_minzoom",
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              4,
              0.5
            ],
            [
              7,
              1
            ]
          ]
        }
      },
      "source-layer": "transport_lines"
    },
    {
      "minzoom": 4,
      "layout": {
        "visibility": "visible"
      },
      "maxzoom": 7,
      "filter": [
        "all",
        [
          "<=",
          "min_zoom",
          5
        ]
      ],
      "type": "line",
      "source": "osm",
      "id": "road_motorway_z4",
      "paint": {
        "line-color": "#4a4a4a",
        "line-width": {
          "stops": [
            [
              4,
              0.5
            ],
            [
              7,
              1
            ]
          ]
        }
      },
      "source-layer": "transport_lines"
    },
    {
      "minzoom": 14,
      "layout": {
        "text-line-height": 1.2,
        "text-size": {
          "stops": [
            [
              14,
              8
            ],
            [
              15,
              14
            ]
          ]
        },
        "text-ignore-placement": false,
        "text-font": [
          "OpenSansRegular"
        ],
        "icon-allow-overlap": true,
        "symbol-placement": "line",
        "visibility": "visible",
        "icon-optional": false,
        "text-field": "{name}"
      },
      "maxzoom": 24,
      "filter": [
        "all"
      ],
      "type": "symbol",
      "source": "osm",
      "id": "label_road_name",
      "paint": {
        "text-halo-color": "#000000",
        "text-halo-width": 0,
        "text-color": "rgba(255, 255, 255, 1)"
      },
      "source-layer": "transport_lines"
    }
  ],
  "sprite": "${server_url}/mobility/osm_tegola_spritesheet3",
  "glyphs": "${server_url}/mobility/fonts/{fontstack}/{range}.pbf",
  "created": "2017-01-04T21:12:33.904Z",
  "name": "mobility3d",
  "bearing": 0,
  "metadata": {
    "mapbox:autocomposite": false,
    "mapbox:type": "template",
    "openmaptiles:version": "3.x",
    "maputnik:renderer": "mbgljs",
    "inspect": true
  },
  "owner": "",
  "zoom": 16.63,
  "center": [
    -74.85003,
    11.0189
  ],
  "version": 8,
  "sources": {
    "osm": {
      "type": "vector",
      "url": "${server_url}/capabilities/osm.json"
    }
  },
  "id": "f4652111-6a00-479a-a650-354311684bb3"
}
  '';
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
port = ":${tegolaPort}"
hostname = "${hostName}"

# Tegola offers three tile caching strategies: "file", "redis", and "s3"
[cache]
type = "file"
basepath = "${stateDir}/cache"

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

    proxy_cache_path ${stateDir}/nginx levels=1:2 keys_zone=my_zone:100m inactive=600m;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    server {
      server_name   localhost;
      listen        ${hostName};

      error_page    500 502 503 504  /50x.html;

      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-Proto $scheme;
      proxy_cache my_zone;
      proxy_redirect     off;
 
      location      / {
        add_header X-Proxy-Cache $upstream_cache_status;
        root      ${staticDir};
      }

      location /capabilities {
        proxy_pass http://localhost:${tegolaPort}/capabilities;
      }

      location /maps {
        proxy_pass http://localhost:${tegolaPort}/maps;
      }

      location /tegola {
        proxy_pass http://localhost:${tegolaPort}/;
      }
      location /index.html {
        etag off;
        add_header etag "\"${builtins.substring 11 32 index-html.outPath}\"";
        alias ${index-html};
      }


      location /style.json {
        etag off;
        add_header etag "\"${builtins.substring 11 32 style-config.outPath}\"";
        alias ${style-config};
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
    nginx -c ${nginx-config} -p ${stateDir}
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
    osmconvert ${country-osm} -B=${area-poly}  -o=${stateDir}/area.pbf
  '';
  puertico-loadarea = pkgs.writeShellScriptBin "puertico-loadarea" ''
    imposm import -connection postgis://puertico:puertico@localhost/puertico -mapping ${imposm-config} -read ${stateDir}/area.pbf -write -overwritecache -srid 4326
    imposm  import -connection postgis://puertico:puertico@localhost/puertico -mapping ${imposm-config} -deployproduction -srid 4326
    psql puertico -a -f  ${piensa.puertico-osm}/postgis_helpers.sql
#    psql puertico -a -f  ${piensa.puertico-osm}/postgis_index.sql
  '';
in pkgs.stdenv.mkDerivation rec {
   name = "puertico";

   src = builtins.filterSource (p: t: pkgs.lib.cleanSourceFilter p t && baseNameOf p != "var") ./.;

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
    puertico-loadarea
    puertico-createarea
   ];
  shellHooks = ''
     mkdir -p ${stateDir}/logs
     mkdir -p ${stateDir}/nginx
     export PGDATA=${stateDir}/data
  '';
}
