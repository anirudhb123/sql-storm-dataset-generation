WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) as rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
), top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_mktsegment
    FROM ranked_orders ro
    WHERE ro.rank <= 10
), order_details AS (
    SELECT 
        to.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM top_orders to
    JOIN lineitem l ON to.o_orderkey = l.l_orderkey
    GROUP BY to.o_orderkey
), supplier_details AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * od.unique_parts) AS total_cost,
        SUM(od.total_revenue) AS total_revenue
    FROM partsupp ps
    JOIN order_details od ON ps.ps_partkey = od.o_orderkey
    GROUP BY ps.ps_suppkey
)
SELECT 
    s.s_name,
    sd.total_cost,
    sd.total_revenue,
    CASE 
        WHEN sd.total_revenue > 0 THEN (sd.total_revenue - sd.total_cost) / sd.total_revenue * 100
        ELSE 0
    END AS profit_margin_percentage
FROM supplier s
JOIN supplier_details sd ON s.s_suppkey = sd.ps_suppkey
ORDER BY profit_margin_percentage DESC
LIMIT 5;
