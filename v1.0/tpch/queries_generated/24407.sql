WITH RECURSIVE SupplyStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        ss.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplyStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.supply_rank <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_return,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ts.s_name, 
    od.o_orderkey, 
    od.total_return,
    o.o_orderdate, 
    COALESCE(od.distinct_parts, 0) AS distinct_items,
    CASE 
        WHEN ts.s_acctbal IS NULL THEN 'No Balance' 
        ELSE CAST(ts.s_acctbal AS VARCHAR)
    END AS balance_status
FROM 
    TopSuppliers ts
FULL OUTER JOIN 
    OrderDetails od ON ts.s_suppkey = (SELECT 
                                            ps.ps_suppkey 
                                        FROM 
                                            partsupp ps 
                                        WHERE 
                                            ps.ps_partkey IN (SELECT DISTINCT l.l_partkey 
                                                              FROM lineitem l 
                                                              JOIN orders o ON l.l_orderkey = o.o_orderkey 
                                                              WHERE o.o_orderstatus = 'F')
                                        ORDER BY ps.ps_supplycost DESC LIMIT 1)
WHERE 
    ts.total_supply_cost > (SELECT 
                                AVG(total_supply_cost) 
                             FROM 
                                SupplyStats)
OR 
    od.o_orderkey IS NULL
ORDER BY 
    ts.s_name, od.o_orderkey;
