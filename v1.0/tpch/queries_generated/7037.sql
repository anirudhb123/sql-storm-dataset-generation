WITH supplier_summary AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineitem_value
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, c.c_name
),
detailed_report AS (
    SELECT ss.s_name, ss.nation, os.c_name, os.total_lineitem_value, os.o_totalprice
    FROM supplier_summary ss
    JOIN order_summary os ON ss.total_supply_cost > os.total_lineitem_value
)
SELECT d.s_name, d.nation, d.c_name, d.total_lineitem_value, d.o_totalprice, 
       (d.o_totalprice - d.total_lineitem_value) AS profit_margin
FROM detailed_report d
ORDER BY profit_margin DESC
LIMIT 10;
