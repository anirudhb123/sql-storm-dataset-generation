WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
), 
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY o.o_orderkey) AS total_line_item_value,
           COUNT(l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
FilteredOrders AS (
    SELECT o.*, 
           CASE 
               WHEN os.total_line_item_value > 1000 THEN 'High Value Order'
               ELSE 'Regular Order'
           END AS order_category
    FROM OrderStats os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(s.s_acctbal) AS total_supplier_balance,
    SUM(CASE WHEN fo.order_category = 'High Value Order' THEN 1 ELSE 0 END) AS high_value_order_count,
    AVG(fo.o_totalprice) AS avg_order_value,
    MAX(fo.o_totalprice) AS max_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS popular_parts
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN (
    SELECT DISTINCT o.o_orderkey, fo.order_category
    FROM FilteredOrders fo
    JOIN orders o ON fo.o_orderkey = o.o_orderkey
) fo ON s.s_suppkey = fo.o_orderkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE p.p_retailprice IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(s.s_acctbal) > 50000
ORDER BY total_supplier_balance DESC;
