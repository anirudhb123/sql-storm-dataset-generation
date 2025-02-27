WITH ranked_orders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
supplier_performance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    tc.c_name AS top_customer,
    sp.s_name AS supplier_name,
    sp.parts_supplied,
    sp.avg_supply_cost,
    ro.total_revenue
FROM 
    ranked_orders ro
JOIN 
    top_customers tc ON ro.total_revenue = (SELECT MAX(total_revenue) FROM ranked_orders WHERE o_orderdate = ro.o_orderdate)
JOIN 
    supplier_performance sp ON sp.parts_supplied > 10
ORDER BY 
    ro.o_orderdate, ro.total_revenue DESC;
