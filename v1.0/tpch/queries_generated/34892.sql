WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, 1 AS level
    FROM region
    WHERE r_name LIKE 'Eastern%'
    
    UNION ALL
    
    SELECT r.r_regionkey, r.r_name, rh.level + 1
    FROM region r
    JOIN RegionHierarchy rh ON r.r_regionkey = rh.r_regionkey - 1
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F')
    GROUP BY c.c_custkey, c.c_name
),
SupplierStats AS (
    SELECT s.s_suppkey, AVG(ps.ps_supplycost) AS avg_supplycost, 
           SUM(ps.ps_availqty) AS total_qty_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
LineItemQuality AS (
    SELECT l.l_orderkey, MAX(l.l_extendedprice * (1 - l.l_discount)) AS max_revenue
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE
    GROUP BY l.l_orderkey
)
SELECT 
    rh.r_name,
    cs.c_name,
    cs.total_spent,
    ss.avg_supplycost,
    ss.total_qty_available,
    COALESCE(lq.max_revenue, 0) AS max_revenue_generated
FROM RegionHierarchy rh
LEFT JOIN CustomerOrderTotals cs ON cs.total_spent > 1000
LEFT JOIN SupplierStats ss ON ss.total_qty_available > 100
LEFT JOIN LineItemQuality lq ON lq.l_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_orderdate BETWEEN DATEADD(MONTH, -6, CURRENT_DATE) AND CURRENT_DATE
)
WHERE rh.level < 3
ORDER BY cs.total_spent DESC, ss.avg_supplycost ASC;
