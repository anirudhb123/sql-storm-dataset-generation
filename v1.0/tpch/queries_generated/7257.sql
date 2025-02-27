WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_n_revenue AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.revenue_rank <= 10
),
nation_supplier AS (
    SELECT 
        su.s_suppkey,
        na.n_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier su
    JOIN 
        nation na ON su.s_nationkey = na.n_nationkey
    JOIN 
        partsupp ps ON su.s_suppkey = ps.ps_suppkey
    GROUP BY 
        su.s_suppkey, na.n_name
),
final_report AS (
    SELECT 
        tn.o_orderkey,
        tn.o_orderdate,
        ns.n_name,
        ns.total_cost,
        tn.total_revenue
    FROM 
        top_n_revenue tn
    JOIN 
        nation_supplier ns ON tn.o_orderkey = (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = tn.o_orderkey LIMIT 1)
)

SELECT 
    fr.o_orderkey,
    fr.o_orderdate,
    fr.n_name,
    fr.total_cost,
    fr.total_revenue,
    (fr.total_revenue - fr.total_cost) AS profit
FROM 
    final_report fr
ORDER BY 
    profit DESC;
