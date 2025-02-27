WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    WHERE o.o_orderdate >= '2023-01-01'
    AND o.o_totalprice - (SELECT SUM(l.l_discount) 
                           FROM lineitem l 
                           WHERE l.l_orderkey = o.o_orderkey) > 1000
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           AVG(l.l_discount) OVER (PARTITION BY l.l_partkey) AS avg_discount
    FROM lineitem l
)
SELECT p.p_partkey, p.p_name, SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
       SUM(l.l_extendedprice) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(l.l_tax) AS highest_tax,
       CASE WHEN s.hierarchy_level IS NOT NULL THEN 'In hierarchy' ELSE 'Out of hierarchy' END AS supplier_status
FROM part p
LEFT JOIN RankedLineItems l ON p.p_partkey = l.l_partkey
LEFT JOIN FilteredOrders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN (
    SELECT s.s_suppkey, sh.level
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
) s ON s.s_suppkey = l.l_suppkey
WHERE p.p_retailprice > 50.00
GROUP BY p.p_partkey, p.p_name, s.hierarchy_level
HAVING SUM(l.l_extendedprice) > 5000
ORDER BY total_sales DESC, total_quantity ASC;
