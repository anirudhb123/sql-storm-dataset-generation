WITH RECURSIVE nation_totals AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT nt.n_nationkey, nt.n_name, SUM(s.s_acctbal)
    FROM nation_totals nt
    JOIN supplier s ON nt.n_nationkey = s.s_nationkey
    GROUP BY nt.n_nationkey, nt.n_name
), part_stats AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supplycost,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2021-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), combined_data AS (
    SELECT n.n_name, pt.p_name, pt.avg_supplycost, os.total_revenue
    FROM nation_totals n
    JOIN part_stats pt ON n.n_nationkey = pt.p_partkey
    FULL OUTER JOIN order_summary os ON os.total_revenue IS NOT NULL
    WHERE os.total_revenue > (SELECT AVG(total_revenue) FROM order_summary) 
      AND pt.avg_supplycost BETWEEN 10.00 AND 50.00
)
SELECT cd.n_name, cd.p_name, cd.avg_supplycost, cd.total_revenue,
       ROW_NUMBER() OVER (PARTITION BY cd.n_name ORDER BY cd.total_revenue DESC) AS revenue_rank
FROM combined_data cd
WHERE cd.avg_supplycost IS NOT NULL
ORDER BY cd.n_name, revenue_rank;
