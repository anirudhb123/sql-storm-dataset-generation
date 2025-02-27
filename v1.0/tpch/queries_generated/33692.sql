WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name AS nation 
    FROM supplier s 
    JOIN nation n ON s.s_nationkey = n.n_nationkey 
    WHERE s.s_acctbal > 5000 

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_nationkey, n.n_name AS nation 
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey 
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),

BaseOrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(l.l_orderkey) AS total_items,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),

RegionPerformance AS (
    SELECT r.r_name, COUNT(DISTINCT c.c_custkey) AS total_customers, SUM(o.o_totalprice) AS total_order_value
    FROM region r 
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey 
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey 
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY r.r_name
)

SELECT rh.nation, bp.total_revenue, bp.total_items, rp.total_customers, rp.total_order_value
FROM SupplierHierarchy rh
JOIN BaseOrderStats bp ON rh.s_suppkey = bp.o_orderkey 
FULL OUTER JOIN RegionPerformance rp ON rh.nation = rp.r_name
WHERE bp.rn <= 10
AND (rp.total_order_value IS NULL OR rp.total_order_value > 10000)
ORDER BY total_revenue DESC, total_order_value ASC;
