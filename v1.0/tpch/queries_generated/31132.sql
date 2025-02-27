WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > (sh.s_acctbal * 0.5)
),
part_sales AS (
    SELECT p.p_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS sales_amount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey
),
customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    n.n_name,
    SUM(ps.ps_availqty) AS total_available,
    AVG(s.s_acctbal) AS average_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_inventory_value,
    CASE 
        WHEN SUM(ps.ps_availqty) > 10000 THEN 'High Inventory'
        ELSE 'Low Inventory'
    END AS inventory_status,
    DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer_orders co ON co.c_custkey = s.s_suppkey
WHERE p.p_retailprice IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING AVG(s.s_acctbal) > 5000
ORDER BY sales_rank, total_available DESC;
