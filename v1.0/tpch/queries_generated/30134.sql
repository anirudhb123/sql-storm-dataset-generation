WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS hierarchy
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           CAST(sh.hierarchy || ' -> ' || s.s_name AS VARCHAR(100))
    FROM supplier s
    JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE sh.s_acctbal < s.s_acctbal
),
part_order_summary AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY p.p_partkey, p.p_name
),
top_parts AS (
    SELECT p_partkey, p_name, total_revenue, order_count
    FROM part_order_summary
    WHERE rn <= 5
)
SELECT r.r_name,
       SUM(COALESCE(ps.ps_availqty, 0)) AS total_available,
       SUM(COALESCE(ps.ps_supplycost * ps.ps_availqty, 0)) AS total_cost,
       STRING_AGG(DISTINCT tp.p_name, ', ') AS part_names,
       COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN top_parts tp ON tp.p_partkey = ps.ps_partkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
ORDER BY total_available DESC 
LIMIT 10;
