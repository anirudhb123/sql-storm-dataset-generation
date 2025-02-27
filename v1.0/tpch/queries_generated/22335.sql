WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),

customer_orders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'O')
),

part_summary AS (
    SELECT p.p_partkey, 
           p.p_name,
           SUM(ps.ps_availqty) AS total_available,
           MAX(ps.ps_supplycost) AS max_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),

order_line_analysis AS (
    SELECT l.l_orderkey,
           COUNT(DISTINCT l.l_partkey) AS distinct_parts,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS line_item_rank
    FROM lineitem l
    GROUP BY l.l_orderkey
    HAVING SUM(l.l_tax) IS NOT NULL
)

SELECT c.c_name, 
       COALESCE(o.order_count, 0) AS total_orders,
       COALESCE(o.total_spent, 0) AS total_spent,
       p.p_name, 
       ps.total_available,
       ps.max_supplycost,
       CASE WHEN l.line_item_rank = 1 THEN 'Highest Revenue' ELSE 'Regular' END AS order_type
FROM customer_orders o
FULL OUTER JOIN part_summary ps ON o.order_count > 0
FULL OUTER JOIN part p ON ps.p_partkey = p.p_partkey
LEFT JOIN order_line_analysis l ON l.l_orderkey = o.order_count
WHERE (p.p_size > 10 AND p.p_retailprice < 50.00) OR (p.p_mfgr LIKE '%XYZ%' AND ps.total_available IS NULL)
ORDER BY total_spent DESC, total_orders DESC, p.p_name;
