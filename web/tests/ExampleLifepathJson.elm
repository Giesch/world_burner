module ExampleLifepathJson exposing (..)


dwarves : String
dwarves =
    """
{
  "lifepaths": [
    {
      "id": 1,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "born guilder",
      "page": 111,
      "years": 21,
      "stat_mod": null,
      "res": 5,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 4,
      "skill_pts": 0,
      "trait_pts": 1,
      "skills": [],
      "traits": [],
      "born": true,
      "requirement": null
    },
    {
      "id": 2,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "wordbearer",
      "page": 111,
      "years": 15,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "hold-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "rumor-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "oratory",
          "page": 286,
          "skill_id": 167,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "clan history",
          "page": 264,
          "skill_id": 57,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "quirky"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "iron memory"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "quick-step"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 3,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "hauler",
      "page": 111,
      "years": 10,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 7,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "hauling",
          "page": 277,
          "skill_id": 123,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "wagon-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "cargo-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "road-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "lifting heavy things"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 4,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "carter",
      "page": 111,
      "years": 20,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "animal husbandry",
          "page": 255,
          "skill_id": 10,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "driving",
          "page": 268,
          "skill_id": 81,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mule-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "patient"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "iron nose"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 5,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "hawker",
      "page": 111,
      "years": 15,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "inconspicuous",
          "page": 278,
          "skill_id": 130,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "streetwise",
          "page": 302,
          "skill_id": 245,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "haggling",
          "page": 276,
          "skill_id": 120,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "spiel-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": null
    },
    {
      "id": 6,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "apprentice",
      "page": 111,
      "years": 15,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 20,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "carving",
          "page": 263,
          "skill_id": 52,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "tanner",
          "page": 304,
          "skill_id": 254,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "carpentry",
          "page": 263,
          "skill_id": 49,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "scutwork-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "seen not heard"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 7,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "journeyman",
      "page": 111,
      "years": 25,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 25,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 7,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "haggling",
          "page": 276,
          "skill_id": 120,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "reputation-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "cartwright",
          "page": 263,
          "skill_id": 51,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "black metal artifice",
          "page": 260,
          "skill_id": 33,
          "magical": true,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "hungry"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 6,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 30,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 22,
                "count": 1
              }
            }
          ]
        },
        "description": "Apprentice or any Ardent lifepath"
      }
    },
    {
      "id": 8,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "craftsman",
      "page": 111,
      "years": 45,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 45,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        }
      ],
      "gen_skill_pts": 1,
      "skill_pts": 4,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "appraisal",
          "page": 255,
          "skill_id": 13,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "shipwright",
          "page": 295,
          "skill_id": 212,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "artificer-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 7,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 32,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 52,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 53,
                "count": 1
              }
            }
          ]
        },
        "description": "Journeyman, Artificer, Artillerist, or Engineer"
      }
    },
    {
      "id": 9,
      "setting_id": 1,
      "setting_name": "guilder",
      "name": "trader",
      "page": 111,
      "years": 45,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 70,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 7,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "stentorious debate",
          "page": 301,
          "skill_id": 239,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "shrewd appraisal",
          "page": 296,
          "skill_id": 213,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "haggling",
          "page": 276,
          "skill_id": 120,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "persuasion",
          "page": 287,
          "skill_id": 171,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 5,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 7,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 37,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 18,
                "count": 1
              }
            }
          ]
        },
        "description": "Hawker, Journeyman, Adventurer, or Husband/Wife"
      }
    },
    {
      "id": 10,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "born clansman",
      "page": 110,
      "years": 20,
      "stat_mod": null,
      "res": 10,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        }
      ],
      "gen_skill_pts": 3,
      "skill_pts": 0,
      "trait_pts": 1,
      "skills": [],
      "traits": [],
      "born": true,
      "requirement": null
    },
    {
      "id": 11,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "tender",
      "page": 110,
      "years": 20,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 7,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "farming",
          "page": 272,
          "skill_id": 99,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "crop-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "hills-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "cursing"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 12,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "herder",
      "page": 110,
      "years": 15,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 9,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "animal husbandry",
          "page": 255,
          "skill_id": 10,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "flock-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "fence building",
          "page": 272,
          "skill_id": 100,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "climbing",
          "page": 264,
          "skill_id": 58,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "TraitEntry",
          "value": {
            "name": "booming voice",
            "trait_id": 2,
            "page": 316,
            "cost": 2,
            "taip": "CallOn"
          }
        },
        {
          "type": "TraitEntry",
          "value": {
            "name": "affinity for sheep and goats",
            "trait_id": 1,
            "page": 311,
            "cost": 4,
            "taip": "Die"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 13,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "tinkerer",
      "page": 110,
      "years": 35,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "stuff-wise",
          "page": 302,
          "skill_id": 246,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "scavenging",
          "page": 294,
          "skill_id": 204,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "curious"
          }
        },
        {
          "type": "TraitEntry",
          "value": {
            "name": "tinkerer",
            "trait_id": 6,
            "page": 350,
            "cost": null,
            "taip": "CallOn"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 14,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "delver",
      "page": 110,
      "years": 20,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "tunnel-wise",
          "page": 306,
          "skill_id": 266,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "gas pocket-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "excavation",
          "page": 271,
          "skill_id": 95,
          "magical": true,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "TraitEntry",
          "value": {
            "name": "deep sense",
            "trait_id": 3,
            "page": 321,
            "cost": null,
            "taip": "Die"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 15,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "miller",
      "page": 110,
      "years": 30,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 30,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "grain appraisal",
          "page": 276,
          "skill_id": 117,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "miller",
          "page": 284,
          "skill_id": 156,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "brewer",
          "page": 262,
          "skill_id": 43,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "grain-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": null
    },
    {
      "id": 16,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "brewer",
      "page": 110,
      "years": 40,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 40,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "beer appraisal",
          "page": 259,
          "skill_id": 29,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "nogger",
          "page": 285,
          "skill_id": 165,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "miller",
          "page": 284,
          "skill_id": 156,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "beer-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 15,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 19,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 25,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 51,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 40,
                "count": 1
              }
            }
          ]
        },
        "description": "Miller, Longbeard, Seneschal, Captain, or Drunk"
      }
    },
    {
      "id": 17,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "foreman",
      "page": 110,
      "years": 35,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 25,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "ore-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "vein-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "engineering",
          "page": 270,
          "skill_id": 90,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 14,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 30,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 53,
                "count": 1
              }
            }
          ]
        },
        "description": "Delver, Artificer's Ardent, or Engineer"
      }
    },
    {
      "id": 18,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "husband/wife",
      "page": 110,
      "years": 70,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 18,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "clan-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "family-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "haggling",
          "page": 276,
          "skill_id": 120,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "soothing platitudes",
          "page": 299,
          "skill_id": 231,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "TraitEntry",
          "value": {
            "name": "dispute-settler",
            "trait_id": 4,
            "page": 321,
            "cost": null,
            "taip": "CallOn"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "pragmatic outlook"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "PreviousLifepaths",
          "value": {
            "count": 2
          }
        },
        "description": "Husband/Wife cannot be the character's second lifepath"
      }
    },
    {
      "id": 19,
      "setting_id": 2,
      "setting_name": "clansman",
      "name": "longbeard",
      "page": 111,
      "years": 77,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 30,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "coarse persuasion",
          "page": 264,
          "skill_id": 60,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "ugly truth",
          "page": 307,
          "skill_id": 268,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "guilder-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "host-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "folksy wisdom"
          }
        },
        {
          "type": "TraitEntry",
          "value": {
            "name": "oathswearer",
            "trait_id": 5,
            "page": 338,
            "cost": null,
            "taip": "Die"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 17,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 32,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 9,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 25,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 37,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 18,
                "count": 1
              }
            }
          ]
        },
        "description": "Foreman, Graybeard, Artificer, Trader, Seneschal, Adventurer or Husband/Wife"
      }
    },
    {
      "id": 20,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "born noble",
      "page": 113,
      "years": 21,
      "stat_mod": null,
      "res": 10,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        }
      ],
      "gen_skill_pts": 4,
      "skill_pts": 2,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "dwarven rune script",
          "page": 269,
          "skill_id": 84,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "dvergar"
          }
        }
      ],
      "born": true,
      "requirement": null
    },
    {
      "id": 21,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "abecedart",
      "page": 113,
      "years": 20,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "chronology of kings",
          "page": 264,
          "skill_id": 55,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "obscure text-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "know it all"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 24,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "chronicler",
      "page": 113,
      "years": 50,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 20,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 9,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "illuminations",
          "page": 278,
          "skill_id": 129,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "ancient history",
          "page": 277,
          "skill_id": 126,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "clan-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "dwarf-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "poetry",
          "page": 288,
          "skill_id": 176,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "cartography",
          "page": 263,
          "skill_id": 50,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "symbology",
          "page": 303,
          "skill_id": 252,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "oath-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 21,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 49,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            }
          ]
        },
        "description": "Abecedart, Khirurgeon, or Graybeard"
      }
    },
    {
      "id": 25,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "seneschal",
      "page": 113,
      "years": 55,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 50,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "estate management",
          "page": 271,
          "skill_id": 92,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "hold-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "practical"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 9,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 19,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 50,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 24,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 49,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            }
          ]
        },
        "description": "Trader, Longbeard, Quartermaster, Chronicler, Khirurgeon, or Graybeard"
      }
    },
    {
      "id": 26,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "treasurer",
      "page": 113,
      "years": 75,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 100,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "accounting",
          "page": 253,
          "skill_id": 1,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "treasure-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "administration",
          "page": 253,
          "skill_id": 3,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "dangerous obsession"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "rain man"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 25,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 32,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 54,
                "count": 1
              }
            }
          ]
        },
        "description": "Seneschal, Artificer, or Warden"
      }
    },
    {
      "id": 27,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "high captain",
      "page": 113,
      "years": 75,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 75,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 2,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "strategy",
          "page": 302,
          "skill_id": 243,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "muttering"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "stentorious voice"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "All",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 23,
                "count": 1
              }
            },
            {
              "type": "Any",
              "value": [
                {
                  "type": "Lifepath",
                  "value": {
                    "lifepath_id": 51,
                    "count": 1
                  }
                },
                {
                  "type": "Lifepath",
                  "value": {
                    "lifepath_id": 54,
                    "count": 1
                  }
                }
              ]
            }
          ]
        },
        "description": "Noble Axe Bearer and either Captain or Warden"
      }
    },
    {
      "id": 28,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "prince",
      "page": 113,
      "years": 100,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 200,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 8,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "intimidation",
          "page": 278,
          "skill_id": 134,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "oratory",
          "page": 286,
          "skill_id": 167,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "burden of the crown-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "grumbling"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "galvanizing presence"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "baleful stare"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "All",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 20,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 23,
                "count": 1
              }
            }
          ]
        },
        "description": "Born Noble and Noble Axe Bearer"
      }
    },
    {
      "id": 29,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "born artificer",
      "page": 112,
      "years": 20,
      "stat_mod": null,
      "res": 15,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 3,
      "skill_pts": 2,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "dwarven rune script",
          "page": 269,
          "skill_id": 84,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [],
      "born": true,
      "requirement": null
    },
    {
      "id": 31,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "tyro artificer",
      "page": 112,
      "years": 21,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 20,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "black metal artifice",
          "page": 260,
          "skill_id": 33,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "dwarven art-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "determined"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 30,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 7,
                "count": 1
              }
            }
          ]
        },
        "description": "Artificer's Ardent or Journeyman"
      }
    },
    {
      "id": 32,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "artificer",
      "page": 112,
      "years": 30,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 35,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 8,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "stone artifice",
          "page": 301,
          "skill_id": 241,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etching",
          "page": 271,
          "skill_id": 93,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "white metal artifice",
          "page": 310,
          "skill_id": 278,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "gem artifice",
          "page": 275,
          "skill_id": 115,
          "magical": true,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "stolid"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 31,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 8,
                "count": 1
              }
            }
          ]
        },
        "description": "Tyro or Craftsman"
      }
    },
    {
      "id": 33,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "mask bearer",
      "page": 112,
      "years": 55,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 50,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "jargon",
          "page": 279,
          "skill_id": 135,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "fire and steel-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "war art",
          "page": 308,
          "skill_id": 273,
          "magical": true,
          "training": false,
          "wise": false
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Lifepath",
          "value": {
            "lifepath_id": 32,
            "count": 1
          }
        },
        "description": "Artificer"
      }
    },
    {
      "id": 34,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "master of arches",
      "page": 112,
      "years": 75,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 75,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 8,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "lithography",
          "page": 281,
          "skill_id": 146,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "sculpture",
          "page": 294,
          "skill_id": 205,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "hallmaster",
          "page": 276,
          "skill_id": 121,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "symbology",
          "page": 303,
          "skill_id": 252,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "confident"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "patient"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Lifepath",
          "value": {
            "lifepath_id": 32,
            "count": 1
          }
        },
        "description": "Artificer"
      }
    },
    {
      "id": 35,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "master of forges",
      "page": 112,
      "years": 75,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 75,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "forge artifice",
          "page": 274,
          "skill_id": 109,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "appraisal",
          "page": 255,
          "skill_id": 13,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "engineering",
          "page": 270,
          "skill_id": 90,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "maker's mark-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "meticulous"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "estimation"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Lifepath",
          "value": {
            "lifepath_id": 33,
            "count": 1
          }
        },
        "description": "Mask Bearer"
      }
    },
    {
      "id": 36,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "master engraver",
      "page": 112,
      "years": 100,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 60,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 2,
      "skill_pts": 4,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "reason of old stone",
          "page": 290,
          "skill_id": 185,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "stone-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "mountain-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Lifepath",
          "value": {
            "lifepath_id": 34,
            "count": 1
          }
        },
        "description": "Master of Arches"
      }
    },
    {
      "id": 37,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "adventurer",
      "page": 116,
      "years": 5,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 12,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "survival",
          "page": 303,
          "skill_id": 250,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "climbing",
          "page": 264,
          "skill_id": 58,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "knots",
          "page": 290,
          "skill_id": 141,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "herbalism",
          "page": 277,
          "skill_id": 125,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "haggling",
          "page": 276,
          "skill_id": 120,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "firebuilding",
          "page": 273,
          "skill_id": 103,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "brawling",
          "page": 261,
          "skill_id": 41,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "knives",
          "page": 279,
          "skill_id": 140,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "sword",
          "page": 303,
          "skill_id": 251,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "crossbow",
          "page": 266,
          "skill_id": 70,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "lock pick",
          "page": 281,
          "skill_id": 147,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "appraisal",
          "page": 255,
          "skill_id": 13,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "obscure history",
          "page": 277,
          "skill_id": 126,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "symbology",
          "page": 303,
          "skill_id": 252,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "lost treasures-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "adventurer"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "boaster"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 38,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "gambler",
      "page": 116,
      "years": 7,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "games of chance",
          "page": 275,
          "skill_id": 114,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "observation",
          "page": 286,
          "skill_id": 166,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "sleight of hand",
          "page": 297,
          "skill_id": 220,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "cheat-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "stone-faced"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 39,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "oathbreaker",
      "page": 116,
      "years": 20,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 5,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "ugly truth",
          "page": 307,
          "skill_id": 268,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "falsehood",
          "page": 271,
          "skill_id": 98,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "oath-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "oathbreaker"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "bitter"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 40,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "drunk",
      "page": 116,
      "years": 10,
      "stat_mod": null,
      "res": 5,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "stentorious singing",
          "page": 301,
          "skill_id": 240,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "drunking",
          "page": 269,
          "skill_id": 83,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "tavern tales-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "drunk"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "despondent"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 41,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "coward",
      "page": 116,
      "years": 15,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 5,
      "leads": [],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 3,
      "skills": [
        {
          "display_name": "inconspicuous",
          "page": 278,
          "skill_id": 130,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "ugly truth",
          "page": 307,
          "skill_id": 268,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "oratory",
          "page": 286,
          "skill_id": 167,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "hypocritical bastards-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "branded a coward"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 42,
      "setting_id": 5,
      "setting_name": "outcast",
      "name": "rune caster",
      "page": 116,
      "years": 20,
      "stat_mod": {
        "type": "Both",
        "value": 1
      },
      "res": 6,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "rune casting",
          "page": 293,
          "skill_id": 202,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "foraging",
          "page": 273,
          "skill_id": 107,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "scavenging",
          "page": 294,
          "skill_id": 204,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "bad end-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "slave to fate"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 43,
      "setting_id": 6,
      "setting_name": "host",
      "name": "foot soldier",
      "page": 114,
      "years": 10,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 6,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "foraging",
          "page": 273,
          "skill_id": 107,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "brawling",
          "page": 261,
          "skill_id": 41,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "hammer",
          "page": 276,
          "skill_id": 122,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "armor training",
          "page": 256,
          "skill_id": 17,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "shield training",
          "page": 295,
          "skill_id": 210,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "cadence-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "salt of the earth"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 44,
      "setting_id": 6,
      "setting_name": "host",
      "name": "arbalester",
      "page": 114,
      "years": 12,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 12,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "crossbow",
          "page": 266,
          "skill_id": 70,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "fletcher",
          "page": 273,
          "skill_id": 105,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "artillery hand",
          "page": 257,
          "skill_id": 21,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "windage-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "squinty"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 45,
      "setting_id": 6,
      "setting_name": "host",
      "name": "banner bearer",
      "page": 114,
      "years": 7,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 10,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "banner-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "intimidation",
          "page": 278,
          "skill_id": 134,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "resigned to death"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "obsessive"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 46,
      "setting_id": 6,
      "setting_name": "host",
      "name": "horncaller",
      "page": 114,
      "years": 7,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 9,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "links",
          "page": 280,
          "skill_id": 145,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "cadence-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "suicidal bravery-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": null
    },
    {
      "id": 48,
      "setting_id": 6,
      "setting_name": "host",
      "name": "graybeard",
      "page": 115,
      "years": 20,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 20,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "intimidation",
          "page": 278,
          "skill_id": 134,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "field dressing",
          "page": 272,
          "skill_id": 101,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "campaign-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "chuffing"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "oddly likeable"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 47,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 23,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 19,
                "count": 1
              }
            },
            {
              "type": "Setting",
              "value": {
                "setting_id": 6,
                "count": 3
              }
            }
          ]
        },
        "description": "Axe Bearer, Longbeard, or three Host lifepaths"
      }
    },
    {
      "id": 49,
      "setting_id": 6,
      "setting_name": "host",
      "name": "khirurgeon",
      "page": 115,
      "years": 25,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 25,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "khirurgy",
          "page": 279,
          "skill_id": 139,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "soothing platitudes",
          "page": 299,
          "skill_id": 231,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "cooking",
          "page": 266,
          "skill_id": 66,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "infection-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 21,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 25,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            }
          ]
        },
        "description": "Abecedart, Seneschal, or Graybeard"
      }
    },
    {
      "id": 50,
      "setting_id": 6,
      "setting_name": "host",
      "name": "quartermaster",
      "page": 115,
      "years": 50,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 35,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 7,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "logistics",
          "page": 281,
          "skill_id": 149,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "accounting",
          "page": 253,
          "skill_id": 1,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "strategy",
          "page": 302,
          "skill_id": 243,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "supply-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        },
        {
          "display_name": "host-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "no nonsense"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 25,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 26,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 9,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            }
          ]
        },
        "description": "Seneschal, Treasurer, Trader, or Graybeard"
      }
    },
    {
      "id": 51,
      "setting_id": 6,
      "setting_name": "host",
      "name": "captain",
      "page": 115,
      "years": 55,
      "stat_mod": {
        "type": "Mental",
        "value": 1
      },
      "res": 40,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 7,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "command",
          "page": 265,
          "skill_id": 63,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "formation fighting",
          "page": 274,
          "skill_id": 111,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "tactics",
          "page": 304,
          "skill_id": 253,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "cartography",
          "page": 263,
          "skill_id": 50,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "graybeard-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 28,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            }
          ]
        },
        "description": "Prince or Graybeard"
      }
    },
    {
      "id": 52,
      "setting_id": 6,
      "setting_name": "host",
      "name": "artillerist",
      "page": 115,
      "years": 55,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 45,
      "leads": [
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 5,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "artillerist",
          "page": 257,
          "skill_id": 20,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "mending",
          "page": 283,
          "skill_id": 154,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "carpentry",
          "page": 263,
          "skill_id": 49,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "structural weakness-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "complaining"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 33,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 8,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 17,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 44,
                "count": 3
              }
            }
          ]
        },
        "description": "Mask Bearer, Craftsman, Foreman, or three Arbalester lifepaths"
      }
    },
    {
      "id": 53,
      "setting_id": 6,
      "setting_name": "host",
      "name": "engineer",
      "page": 115,
      "years": 60,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 50,
      "leads": [
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 6,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "jargon",
          "page": 279,
          "skill_id": 135,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "war engineer",
          "page": 308,
          "skill_id": 274,
          "magical": true,
          "training": false,
          "wise": false
        },
        {
          "display_name": "scavenging",
          "page": 294,
          "skill_id": 204,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "leverage-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "estimation"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 52,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 33,
                "count": 1
              }
            }
          ]
        },
        "description": "Artillerist or Mask Bearer"
      }
    },
    {
      "id": 54,
      "setting_id": 6,
      "setting_name": "host",
      "name": "warden",
      "page": 115,
      "years": 75,
      "stat_mod": {
        "type": "Either",
        "value": 1
      },
      "res": 65,
      "leads": [
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 7,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "oratory",
          "page": 286,
          "skill_id": 167,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "observation",
          "page": 286,
          "skill_id": 166,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "strategy",
          "page": 302,
          "skill_id": 243,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "etiquette",
          "page": 271,
          "skill_id": 94,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "champion-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "chuntering"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "hard as nails"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 28,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 51,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 27,
                "count": 1
              }
            }
          ]
        },
        "description": "Prince, Captain, or High Captain"
      }
    },
    {
      "id": 22,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "ardent",
      "page": 113,
      "years": 25,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "artificer",
          "setting_id": 4,
          "setting_page": 112
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "sing",
          "page": 297,
          "skill_id": 218,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "soothing platitudes",
          "page": 299,
          "skill_id": 231,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "accounting",
          "page": 253,
          "skill_id": 1,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "whispered secrets-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "humility in the face of your betters"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 23,
      "setting_id": 3,
      "setting_name": "noble",
      "name": "axe bearer",
      "page": 113,
      "years": 20,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 25,
      "leads": [
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 8,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "axe",
          "page": 258,
          "skill_id": 25,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "armor training",
          "page": 256,
          "skill_id": 17,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "shield training",
          "page": 295,
          "skill_id": 210,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "formation fighting",
          "page": 274,
          "skill_id": 111,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "throwing",
          "page": 304,
          "skill_id": 258,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "proud"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 22,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 45,
                "count": 1
              }
            }
          ]
        },
        "description": "Noble Ardent or Banner Bearer"
      }
    },
    {
      "id": 30,
      "setting_id": 4,
      "setting_name": "artificer",
      "name": "ardent",
      "page": 112,
      "years": 21,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "clansman",
          "setting_id": 2,
          "setting_page": 110
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        },
        {
          "setting_name": "host",
          "setting_id": 6,
          "setting_page": 114
        },
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 4,
      "trait_pts": 2,
      "skills": [
        {
          "display_name": "firebuilding",
          "page": 273,
          "skill_id": 103,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "soothing platitudes",
          "page": 299,
          "skill_id": 231,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "soot-wise",
          "page": 309,
          "skill_id": 281,
          "magical": false,
          "training": false,
          "wise": true
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "humility"
          }
        },
        {
          "type": "CharTrait",
          "value": {
            "name": "hard work"
          }
        }
      ],
      "born": false,
      "requirement": null
    },
    {
      "id": 47,
      "setting_id": 6,
      "setting_name": "host",
      "name": "axe bearer",
      "page": 114,
      "years": 15,
      "stat_mod": {
        "type": "Physical",
        "value": 1
      },
      "res": 15,
      "leads": [
        {
          "setting_name": "guilder",
          "setting_id": 1,
          "setting_page": 111
        },
        {
          "setting_name": "outcast",
          "setting_id": 5,
          "setting_page": 116
        },
        {
          "setting_name": "noble",
          "setting_id": 3,
          "setting_page": 113
        }
      ],
      "gen_skill_pts": 0,
      "skill_pts": 9,
      "trait_pts": 1,
      "skills": [
        {
          "display_name": "foraging",
          "page": 273,
          "skill_id": 107,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "axe",
          "page": 258,
          "skill_id": 25,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "conspicuous",
          "page": 266,
          "skill_id": 65,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "intimidation",
          "page": 278,
          "skill_id": 134,
          "magical": false,
          "training": false,
          "wise": false
        },
        {
          "display_name": "armor training",
          "page": 256,
          "skill_id": 17,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "shield training",
          "page": 295,
          "skill_id": 210,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "formation fighting",
          "page": 274,
          "skill_id": 111,
          "magical": false,
          "training": true,
          "wise": false
        },
        {
          "display_name": "throwing",
          "page": 304,
          "skill_id": 258,
          "magical": false,
          "training": false,
          "wise": false
        }
      ],
      "traits": [
        {
          "type": "CharTrait",
          "value": {
            "name": "swaggering"
          }
        }
      ],
      "born": false,
      "requirement": {
        "predicate": {
          "type": "Any",
          "value": [
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 22,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 48,
                "count": 1
              }
            },
            {
              "type": "Lifepath",
              "value": {
                "lifepath_id": 45,
                "count": 1
              }
            }
          ]
        },
        "description": "Noble Ardent, Graybeard, or Banner Bearer"
      }
    }
  ]
}
    """
