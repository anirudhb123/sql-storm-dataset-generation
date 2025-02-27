
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSizeStats AS (
    SELECT p.p_partkey, 
           AVG(ps.ps_availqty) AS avg_availqty, 
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
OrderDetails AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_linenumber) AS total_items,
           MAX(l.l_shipdate) AS last_ship_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationStats AS (
    SELECT n.n_name,
           SUM(CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE 1 END) AS customer_count,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_name
)
SELECT n.n_name, 
       n.customer_count,
       n.order_count,
       p.p_partkey AS p_partkey, -- Assuming there's a p_name column in part
       p.avg_availqty,
       CASE 
           WHEN n.order_count = 0 THEN NULL 
           ELSE SUM(od.total_sales) / n.order_count 
       END AS avg_sales_per_order,
       CASE 
           WHEN ph.level IS NULL THEN 'No Hierarchy' 
           ELSE CONCAT('Level ', ph.level) 
       END AS supplier_hierarchy_level
FROM NationStats n
JOIN PartSizeStats p ON n.order_count < p.supplier_count
LEFT JOIN SupplierHierarchy ph ON ph.level = 0
LEFT JOIN OrderDetails od ON od.o_orderkey = (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderstatus = 'F' 
    ORDER BY o_orderdate DESC 
    LIMIT 1
)
GROUP BY n.n_name, n.customer_count, n.order_count, p.p_partkey, p.avg_availqty, ph.level
HAVING p.avg_availqty IS NOT NULL 
       AND (n.customer_count > 0 OR (n.customer_count = 0 AND p.avg_availqty < 10))
ORDER BY n.n_name, avg_sales_per_order DESC NULLS LAST;
