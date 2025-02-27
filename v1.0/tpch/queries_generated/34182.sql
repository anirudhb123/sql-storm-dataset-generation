WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate <= '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
NationSupplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
LineItemWithWindow AS (
    SELECT l.*, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank,
           SUM(l.l_extendedprice) OVER (PARTITION BY l.l_orderkey) AS total_order_value
    FROM lineitem l
)
SELECT 
    co.total_orders, 
    co.avg_order_value,
    ns.n_name, 
    ns.supplier_count, 
    tp.p_name, 
    tp.total_revenue,
    sh.s_name,
    lw.l_orderkey,
    lw.l_linenumber,
    CASE 
        WHEN lw.l_discount IS NULL THEN 'No Discount'
        ELSE CAST(lw.l_discount * 100 AS varchar) || '% Discount'
    END AS discount_info
FROM CustomerOrderStats co
JOIN NationSupplier ns ON co.c_custkey = (SELECT MIN(c.c_custkey) FROM customer c WHERE c.c_nationkey = ns.n_nationkey)
JOIN TopParts tp ON co.avg_order_value > (SELECT AVG(avg_order_value) FROM CustomerOrderStats)
JOIN SupplierHierarchy sh ON sh.level < 3
JOIN LineItemWithWindow lw ON lw.l_orderkey = (SELECT MIN(o.o_orderkey) FROM orders o WHERE o.o_custkey = co.c_custkey)
WHERE ns.supplier_count > 5
ORDER BY co.total_orders DESC, total_revenue DESC;
