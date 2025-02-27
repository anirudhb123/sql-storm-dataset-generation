WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.level < 5
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
filtered_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > 1000
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, 
       AVG(f.total_spent) AS average_spent, 
       SUM(CASE WHEN l.l_discount > 0.1 THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS discounted_total
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = n.n_nationkey
LEFT JOIN lineitem l ON l.l_suppkey = sh.s_suppkey
LEFT JOIN filtered_customers f ON f.c_custkey = l.l_orderkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 2 OR AVG(f.total_spent) > 5000
ORDER BY average_spent DESC;
