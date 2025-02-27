WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE s.s_acctbal > sh.acctbal
),
part_stats AS (
    SELECT p_partkey, 
           COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(l.l_quantity) AS total_quantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
    GROUP BY p_partkey
),
customer_orders AS (
    SELECT c.c_custkey, 
           c.c_name,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
ranked_parts AS (
    SELECT p.p_partkey, 
           p.p_name,
           ps.supplier_count,
           ps.avg_supplycost,
           ps.total_quantity,
           ps.total_revenue,
           ROW_NUMBER() OVER (ORDER BY ps.total_revenue DESC) AS part_rank
    FROM part_stats ps
    JOIN part p ON ps.p_partkey = p.p_partkey
)
SELECT rh.suppkey, 
       rh.s_name, 
       rh.level, 
       rp.p_name, 
       rp.total_revenue, 
       co.total_spent
FROM supplier_hierarchy rh
FULL OUTER JOIN ranked_parts rp ON rh.s_nationkey = rp.supplier_count
FULL OUTER JOIN customer_orders co ON co.rank = 1
WHERE rp.total_revenue IS NOT NULL AND co.total_spent IS NOT NULL
ORDER BY rh.level, rp.total_revenue DESC;
