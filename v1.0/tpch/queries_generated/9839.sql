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
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.total_revenue
    FROM 
        ranked_orders ro
    WHERE 
        ro.revenue_rank <= 10
),
supplier_region AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name AS region_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
),
order_supplier AS (
    SELECT 
        to.o_orderkey,
        sr.s_suppkey,
        sr.s_name,
        sr.region_name,
        sr.total_supply_cost,
        to.total_revenue
    FROM 
        top_orders to
    JOIN 
        lineitem l ON to.o_orderkey = l.l_orderkey
    JOIN 
        partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
    JOIN 
        supplier_region sr ON ps.ps_suppkey = sr.s_suppkey
)
SELECT 
    os.o_orderkey, 
    os.s_suppkey, 
    os.s_name, 
    os.region_name, 
    os.total_supply_cost, 
    os.total_revenue,
    (os.total_revenue / NULLIF(os.total_supply_cost, 0)) AS revenue_to_cost_ratio
FROM 
    order_supplier os
ORDER BY 
    os.o_orderkey, os.s_suppkey;
