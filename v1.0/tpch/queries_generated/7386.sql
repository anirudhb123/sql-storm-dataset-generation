WITH RECURSIVE supplier_cte AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, p.p_partkey, ps.ps_supplycost * (1 - p.p_retailprice / 100) AS adjusted_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.n_nationkey, p.p_partkey, ps.ps_supplycost * (1 - p.p_retailprice / 100) AS adjusted_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier_cte cte ON cte.s_nationkey = s.s_nationkey
    WHERE p.p_retailprice <= 100
),
nation_summary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count, SUM(cte.adjusted_cost) AS total_adjusted_cost
    FROM nation n
    JOIN supplier_cte cte ON n.n_nationkey = cte.s_nationkey
    GROUP BY n.n_name
)
SELECT n.n_name, n.supplier_count, n.total_adjusted_cost
FROM nation_summary n
ORDER BY n.total_adjusted_cost DESC
LIMIT 10;
