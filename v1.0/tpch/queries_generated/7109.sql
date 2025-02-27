WITH supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
part_data AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, s_data.nation_name
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier_data s_data ON ps.ps_suppkey = s_data.s_suppkey
),
order_summary AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_custkey
),
final_report AS (
    SELECT s_data.nation_name, p_data.p_name, SUM(os.total_revenue) AS total_revenue
    FROM order_summary os
    JOIN customer c ON os.o_custkey = c.c_custkey
    JOIN supplier_data s_data ON c.c_nationkey = s_data.s_nationkey
    JOIN part_data p_data ON s_data.s_suppkey = p_data.p_partkey
    GROUP BY s_data.nation_name, p_data.p_name
)
SELECT nation_name, p_name, total_revenue
FROM final_report
ORDER BY nation_name, total_revenue DESC
LIMIT 10;
