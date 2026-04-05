Config = {}

Config.Debug = true

Config.StashSlots = 20
Config.StashWeight = 100000

Config.TickRate = 2000

Config.Process = {
    mash = {
        activeTime = 60,
        passiveTime = 1800
    },
    ferment = {
        activeTime = 45,
        passiveTime = 7200
    },
    distill = {
        activeTime = 90,
        passiveTime = 3600
    }
}

Config.Props = {
    mash_tub = {
        label = "Mash Tub",
        model = `prop_barrel_02a`,
        stages = { "mash" },

        capacity = 50,

        heat = {
            speed = 1.0,
            retention = 0.85,
            max = 95.0,
            optimalMin = 60.0,
            optimalMax = 75.0
        }
    },

    fermenter = {
        label = "Fermenter",
        model = `prop_barrel_03d`,
        stages = { "ferment" },

        capacity = 50,

        pressure = {
            build = 1.0,
            release = 0.5,
            max = 100.0,
            optimalMin = 40.0,
            optimalMax = 70.0
        }
    },

    still = {
        label = "Still",
        model = `prop_still`,
        stages = { "distill" },

        capacity = 50,

        heat = {
            speed = 1.2,
            retention = 0.9,
            max = 120.0,
            optimalMin = 78.0,
            optimalMax = 90.0
        }
    }
}

Config.Recipes = {
    basic_shine = {
        label = "Basic Moonshine",

        mash = {
            minTemp = 60,
            maxTemp = 75,
            cookTime = 100
        },

        ingredients = {
            mash = {
                corn = 2,
                water = 1
            },

            ferment = {
                yeast = 1
            }
        },

        output = {
            item = "moonshine",
            baseYield = 10,
            baseQuality = 50,
            difficulty = 1.0
        }
    },

    sweet_shine = {
        label = "Sweet Moonshine",

        mash = {
            minTemp = 58,
            maxTemp = 72,
            cookTime = 110
        },

        ingredients = {
            mash = {
                corn = 2,
                sugar = 2,
                water = 1
            },

            ferment = {
                yeast = 1
            }
        },

        output = {
            item = "sweet_moonshine",
            baseYield = 10,
            baseQuality = 60,
            difficulty = 1.2
        }
    },

    strong_shine = {
        label = "Strong Moonshine",

        mash = {
            minTemp = 65,
            maxTemp = 80,
            cookTime = 120
        },

        ingredients = {
            mash = {
                corn = 3,
                water = 1
            },

            ferment = {
                yeast = 2
            }
        },

        output = {
            item = "strong_moonshine",
            baseYield = 10,
            baseQuality = 70,
            difficulty = 1.5
        }
    }
}