WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),

order_totals AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),

customer_sales AS (
    SELECT c.c_custkey, c.c_name, SUM(ot.total_sales) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN order_totals ot ON o.o_orderkey = ot.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),

part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, s.s_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT rh.r_name, 
       COUNT(DISTINCT cs.c_custkey) AS total_customers, 
       SUM(cs.total_spent) AS total_revenue,
       AVG(sh.level) AS avg_supplier_level,
       ARRAY_AGG(DISTINCT ps.p_name) FILTER (WHERE ps.ps_availqty > 0) AS available_parts,
       CASE 
           WHEN MAX(cs.total_spent) IS NULL THEN 'No Spending'
           ELSE 'Spending Found'
       END AS spending_status
FROM region rh
JOIN nation n ON rh.r_regionkey = n.n_regionkey
JOIN customer_sales cs ON n.n_nationkey = cs.c_custkey
JOIN supplier_hierarchy sh ON cs.c_custkey = sh.s_nationkey
LEFT JOIN part_supplier ps ON ps.ps_supplycost < 100
WHERE n.n_name IS NOT NULL 
GROUP BY rh.r_name
HAVING SUM(cs.total_spent) > 100000
ORDER BY total_revenue DESC;
