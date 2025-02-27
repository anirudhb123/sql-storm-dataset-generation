WITH RECURSIVE supplier_recursive AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sr.level + 1
    FROM supplier s
    INNER JOIN supplier_recursive sr ON s.s_nationkey = sr.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
avg_part_price AS (
    SELECT AVG(p.p_retailprice) AS avg_price
    FROM part p
    WHERE p.p_size > 10
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT avg(total_spent) FROM (
        SELECT SUM(o_totalprice) AS total_spent 
        FROM orders 
        GROUP BY o_custkey
    ) AS customer_totals)
),
lineitem_details AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    WHERE l.l_shipdate >= DATE '2023-10-01'
    GROUP BY l.l_orderkey
)
SELECT sr.s_name, sr.s_acctbal, c.c_name, cos.order_count, cos.total_spent,
       lp.unique_parts, lp.net_revenue
FROM supplier_recursive sr
JOIN partsupp ps ON sr.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem_details lp ON lp.l_orderkey IN (SELECT o.o_orderkey FROM orders o 
                                               INNER JOIN customer_order_summary cos 
                                               ON o.o_custkey = cos.c_custkey)
LEFT JOIN customer_order_summary cos ON sr.s_nationkey = cos.c_custkey
WHERE p.p_retailprice > (SELECT avg_price FROM avg_part_price)
AND sr.level = (SELECT MAX(level) FROM supplier_recursive)
ORDER BY sr.s_acctbal DESC, cos.total_spent DESC;
