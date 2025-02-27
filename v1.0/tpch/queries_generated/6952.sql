WITH high_value_orders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    hv.o_orderkey,
    hv.o_orderdate,
    sd.s_suppkey,
    sd.s_name,
    ns.n_name,
    hv.total_value,
    sd.total_cost,
    ns.supplier_count
FROM high_value_orders hv
JOIN supplier_details sd ON sd.total_cost > (SELECT AVG(total_cost) FROM supplier_details)
JOIN nation_summary ns ON sd.s_nationkey = ns.n_nationkey
ORDER BY hv.o_orderdate DESC, hv.total_value DESC;
