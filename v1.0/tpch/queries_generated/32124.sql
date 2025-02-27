WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 0 AS level 
    FROM region 
    WHERE r_regionkey = 1 -- Assuming region with key 1 is the root
    UNION ALL
    SELECT r.r_regionkey, r.r_name, rh.level + 1 
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey <> rh.r_regionkey
),
SupplierMetrics AS (
    SELECT
        s.n_nationkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.n_nationkey
),
OrderStatistics AS (
    SELECT
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    GROUP BY c.c_nationkey
)

SELECT
    n.n_name,
    COALESCE(sm.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(os.total_orders, 0) AS total_orders,
    COALESCE(os.total_revenue, 0) AS total_revenue,
    CASE
        WHEN COALESCE(os.total_revenue, 0) > 0 THEN
            ROUND((COALESCE(sm.total_avail_qty, 0) / NULLIF(os.total_revenue, 0)), 4) 
        ELSE 
            0
    END AS revenue_per_avail_qty,
    rh.level AS region_level
FROM nation n
LEFT JOIN SupplierMetrics sm ON n.n_nationkey = sm.n_nationkey
LEFT JOIN OrderStatistics os ON n.n_nationkey = os.c_nationkey
JOIN RegionHierarchy rh ON n.n_regionkey = rh.r_regionkey
WHERE n.n_comment IS NOT NULL 
ORDER BY n.n_name;
