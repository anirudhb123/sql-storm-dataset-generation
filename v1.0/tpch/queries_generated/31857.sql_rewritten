WITH RECURSIVE supplier_cte AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, c.level + 1
    FROM supplier s
    INNER JOIN supplier_cte c ON s.s_nationkey = c.s_nationkey
    WHERE c.level < 3
),
part_sales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY p.p_partkey, p.p_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
avg_sales AS (
    SELECT AVG(total_spent) AS avg_spent FROM customer_order_summary
)
SELECT r.r_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       COALESCE(SUM(ps.ps_availqty), 0) AS total_avail_qty,
       COALESCE(SUM(ps.ps_supplycost), 0) AS total_supply_cost,
       p.p_name,
       p.total_sales,
       c.order_count,
       CASE 
           WHEN c.total_spent > a.avg_spent THEN 'Above Average'
           ELSE 'Below Average'
       END AS customer_status
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part_sales p ON ps.ps_partkey = p.p_partkey
LEFT JOIN customer_order_summary c ON s.s_nationkey = c.c_custkey
CROSS JOIN avg_sales a
WHERE s.s_acctbal IS NOT NULL
GROUP BY r.r_name, p.p_name, p.total_sales, c.order_count, c.total_spent, a.avg_spent
ORDER BY r.r_name, p.total_sales DESC;