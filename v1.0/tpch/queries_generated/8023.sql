WITH ranked_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
top_suppliers AS (
    SELECT * FROM ranked_suppliers WHERE rank <= 3
),
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.r_name, SUM(os.total_revenue) AS total_revenue, COUNT(DISTINCT ts.s_suppkey) AS unique_suppliers
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN top_suppliers ts ON s.s_suppkey = ts.s_suppkey
JOIN order_summary os ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p WHERE p.p_container IN ('SM BOX', 'MED BAG')
    )
)
GROUP BY r.r_name
ORDER BY total_revenue DESC;
