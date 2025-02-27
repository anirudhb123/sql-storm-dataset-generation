WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, NULL::integer as parent_suppkey
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.s_suppkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
    WHERE c.c_acctbal > 10000
),
LineItemAnalytics AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) as total_sales,
           COUNT(l.l_linenumber) as total_items,
           MAX(l.l_shipdate) as last_ship_date
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT n.n_name, 
       r.r_name, 
       COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(l.total_sales) AS total_revenue,
       AVG(s.s_acctbal) as avg_supplier_acctbal,
       ARRAY_AGG(DISTINCT sp.s_name) AS suppliers_list
FROM nation n
JOIN region r ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighValueCustomers c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_shipdate > NOW() - INTERVAL '30 days'))
LEFT JOIN LineItemAnalytics l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
LEFT JOIN SupplierHierarchy sp ON sp.s_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name, r.r_name
HAVING SUM(l.total_sales) > 10000000
ORDER BY total_revenue DESC;
