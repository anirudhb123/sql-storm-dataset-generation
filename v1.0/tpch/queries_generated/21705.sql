WITH RecursiveSupplierCosts AS (
    SELECT ps_suppkey, SUM(ps_supplycost) AS total_cost
    FROM partsupp
    GROUP BY ps_suppkey
    UNION ALL
    SELECT ps_suppkey, total_cost * (1 + 0.05)
    FROM RecursiveSupplierCosts
    WHERE total_cost < 5000
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rnk
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 100
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    WHERE EXISTS (
          SELECT 1 
          FROM RecursiveSupplierCosts r 
          WHERE r.ps_suppkey = s.s_suppkey 
          AND r.total_cost > 1000
    )
),
MatchingOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') 
    GROUP BY o.o_orderkey, o.o_custkey
),
RegionFilter AS (
    SELECT r.r_regionkey, r.r_name
    FROM region r
    WHERE r.r_comment IS NOT NULL AND CHAR_LENGTH(r.r_comment) > 50
)
SELECT DISTINCT f.c_name, 
                COALESCE(AVG(m.revenue), 0) AS average_revenue,
                COUNT(h.s_suppkey) AS supplier_count,
                INITCAP(r.r_name) AS region_name
FROM FilteredCustomers f
LEFT JOIN MatchingOrders m ON f.c_custkey = m.o_custkey
LEFT JOIN HighValueSuppliers h ON h.s_nationkey = f.c_nationkey
LEFT JOIN nation n ON f.c_nationkey = n.n_nationkey
JOIN RegionFilter r ON n.n_regionkey = r.r_regionkey
WHERE f.rnk = 1
GROUP BY f.c_name, r.r_name
HAVING AVG(m.revenue) > 5000 OR COUNT(h.s_suppkey) > 10
ORDER BY average_revenue DESC NULLS LAST;
