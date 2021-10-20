return {
    -- 集群
    cluster = {
        node1 = "121.5.162.34:7001",
        node2 = "121.5.162.34:7002"
    },
    agentmgr = {
        node = "node1"
    },
    scene = {
        node1 = {1001, 1002},
        -- node2 = {1003}
    },

    --节点1
    node1 = {
        debug = {
            port = 8100
        },
        gateway = {
            [1] = {port = 8101},
            [2] = {port = 8102}
        },
        login = {
            [1] = {},
            [2] = {}
        }
    },

    --节点1
    node2 = {
        debug = {
            port = 8200
        },
        gateway = {
            [1] = {port = 8201},
            [2] = {port = 8202}
        },
        login = {
            [1] = {},
            [2] = {}
        }
    }
}