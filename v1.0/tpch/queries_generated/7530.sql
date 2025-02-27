WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 10
),
supplier_part_cost AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(sp.total_supplycost) AS supplier_cost
    FROM 
        supplier s
    JOIN 
        supplier_part_cost sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.revenue,
    sd.s_name,
    sd.supplier_cost
FROM 
    top_orders to
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
JOIN 
    supplier_details sd ON l.l_suppkey = sd.s_suppkey
ORDER BY 
    to.o_orderdate, to.revenue DESC;
