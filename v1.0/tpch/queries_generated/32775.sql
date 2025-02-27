WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
total_sales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
customer_total AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
average_orders AS (
    SELECT AVG(total_spent) AS avg_spent
    FROM customer_total
),
part_availability AS (
    SELECT p.p_partkey, SUM(ps.ps_availqty) AS total_avail
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name,
    COALESCE(sum(ct.total_spent), 0) AS total_customer_spend,
    COUNT(DISTINCT sh.s_suppkey) AS num_suppliers,
    AVG(pt.total_avail) AS avg_avail_parts,
    AVG(t.total) AS avg_order_value
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN customer_total ct ON ct.total_spent > (SELECT avg_spent FROM average_orders)
LEFT JOIN total_sales t ON t.o_orderkey = ct.c_custkey
LEFT JOIN part_availability pt ON pt.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
GROUP BY r.r_name
HAVING COUNT(DISTINCT sh.s_suppkey) > 0
ORDER BY total_customer_spend DESC, avg_avail_parts DESC;
