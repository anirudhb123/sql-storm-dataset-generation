WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS distinct_customers,
        SUM(c.c_acctbal) AS total_balances
    FROM 
        nation n
    LEFT JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    ds.total_price,
    ds.item_count,
    ns.distinct_customers,
    ns.total_balances
FROM 
    NationStats ns
LEFT JOIN 
    SupplierStats ss ON ns.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey LIMIT 1)
LEFT JOIN 
    OrderDetails ds ON ds.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = ns.n_nationkey)
ORDER BY 
    ns.n_name, total_supply_cost DESC, total_balances DESC;
