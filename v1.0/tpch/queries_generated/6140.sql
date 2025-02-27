WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    GROUP BY l.l_orderkey
),
ranked_orders AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_totalprice, lo.total_revenue,
           RANK() OVER (PARTITION BY co.c_custkey ORDER BY lo.total_revenue DESC) AS revenue_rank
    FROM customer_order co
    JOIN lineitem_summary lo ON co.o_orderkey = lo.l_orderkey
),
top_suppliers AS (
    SELECT sp.s_suppkey, sp.s_name, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
    FROM supplier_part sp
    GROUP BY sp.s_suppkey, sp.s_name
    HAVING SUM(sp.ps_supplycost * sp.ps_availqty) > 10000
)
SELECT ro.c_custkey, ro.c_name, ro.o_orderkey, ro.o_totalprice, ro.total_revenue, ts.s_suppkey, ts.s_name, ts.total_supply_cost
FROM ranked_orders ro
JOIN top_suppliers ts ON ro.revenue_rank <= 10
ORDER BY ro.c_custkey, ro.total_revenue DESC;
