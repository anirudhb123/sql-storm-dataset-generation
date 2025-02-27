WITH RankedOrderTotals AS (
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
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
TopOrders AS (
    SELECT 
        orderdate,
        total_revenue 
    FROM 
        RankedOrderTotals 
    WHERE 
        revenue_rank <= 10
)
SELECT 
    r.r_name AS region_name,
    SUM(To.total_revenue) AS total_revenue_from_top_orders,
    COUNT(DISTINCT c.c_custkey) AS unique_customers
FROM 
    TopOrders To
JOIN 
    customer c ON To.orderdate = c.c_custkey
JOIN 
    supplier s ON c.c_nationkey = s.s_nationkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_from_top_orders DESC;
