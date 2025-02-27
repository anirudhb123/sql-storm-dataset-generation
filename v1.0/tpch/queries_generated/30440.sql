WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
regions_with_orders AS (
    SELECT r.r_name, COUNT(o.o_orderkey) AS order_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
),
top_customers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000.00
),
partitioned_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
)
SELECT r.r_name, COALESCE(o.order_count, 0) AS order_count,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(to.total_spent) AS total_spent_by_customers,
       (SELECT COUNT(*) FROM lineitem l WHERE l.l_discount > 0.10) AS discounted_items,
       AVG(p.ps_supplycost) AS avg_supplycost
FROM regions_with_orders o
JOIN regions r ON o.r_name = r.r_name
LEFT JOIN top_customers to ON to.c_custkey = ANY(SELECT DISTINCT o.o_custkey FROM orders o)
LEFT JOIN partsupp p ON p.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.order_count)
WHERE r.r_name IS NOT NULL AND r.r_name NOT IN (SELECT r_name FROM region WHERE r_comment IS NULL)
GROUP BY r.r_name
HAVING COUNT(DISTINCT o.order_count) > 10
ORDER BY r.r_name;
