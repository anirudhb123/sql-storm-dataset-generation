
WITH SupplierCosts AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS parts_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
), 
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost,
        sc.parts_count
    FROM supplier s
    JOIN SupplierCosts sc ON s.s_suppkey = sc.ps_suppkey
    WHERE sc.total_cost > (
        SELECT AVG(total_cost) 
        FROM SupplierCosts
    )
), 
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS RN
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    COALESCE(SUM(hcs.total_cost), 0) AS total_high_cost,
    COALESCE(SUM(rn.total_revenue), 0) AS total_recent_revenue
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN HighCostSuppliers hcs ON ns.n_nationkey = (
    SELECT s.s_nationkey 
    FROM supplier s 
    WHERE s.s_suppkey = hcs.s_suppkey
)
LEFT JOIN RecentOrders rn ON ns.n_nationkey = (
    SELECT c.c_nationkey 
    FROM customer c 
    WHERE c.c_custkey = rn.o_custkey
)
WHERE r.r_name LIKE 'A%'
GROUP BY r.r_name
HAVING COUNT(DISTINCT ns.n_nationkey) > 1
ORDER BY total_recent_revenue DESC, total_high_cost ASC;
