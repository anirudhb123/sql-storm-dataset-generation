WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.level * 1000
),
part_avg_price AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
order_details AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o  
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    p.p_name,
    COALESCE(pa.avg_supplycost, 0) AS avg_supplycost,
    n.n_name AS nation_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(o.total_revenue) AS total_revenue,
    RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.total_revenue) DESC) AS revenue_rank
FROM part p
LEFT JOIN part_avg_price pa ON p.p_partkey = pa.ps_partkey
JOIN lineitem l ON l.l_partkey = p.p_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN supplier_hierarchy sh ON sh.s_suppkey = l.l_suppkey
JOIN nation n ON sh.s_nationkey = n.n_nationkey
WHERE n.n_name IS NOT NULL
GROUP BY p.p_name, pa.avg_supplycost, n.n_name
HAVING SUM(l.l_quantity) > 0
ORDER BY revenue_rank, total_revenue DESC;
