WITH SupplierTotalCosts AS (
    SELECT 
        ps.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.s_suppkey
),
HighestCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        stc.total_supply_cost
    FROM supplier s
    JOIN SupplierTotalCosts stc ON s.s_suppkey = stc.s_suppkey
    WHERE stc.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierTotalCosts)
),
NationSupplierDetails AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT hs.s_suppkey) AS supplier_count,
        SUM(stc.total_supply_cost) AS total_nation_cost
    FROM nation n
    LEFT JOIN HighestCostSuppliers hs ON n.n_nationkey = hs.s_nationkey
    LEFT JOIN SupplierTotalCosts stc ON hs.s_suppkey = stc.s_suppkey
    GROUP BY n.n_name
),
OrderCounts AS (
    SELECT 
        c.c_nationkey,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_nationkey
)
SELECT 
    n.n_name,
    ns.supplier_count,
    ns.total_nation_cost,
    oc.order_count,
    ROUND((ns.total_nation_cost / NULLIF(oc.order_count, 0)), 2) AS cost_per_order
FROM nation n
JOIN NationSupplierDetails ns ON n.n_nationkey = ns.nation_name
JOIN OrderCounts oc ON n.n_nationkey = oc.c_nationkey
ORDER BY cost_per_order DESC
LIMIT 10;
