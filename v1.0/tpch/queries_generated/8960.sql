WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_nationkey
),
TopRevenues AS (
    SELECT 
        r.r_name,
        ro.revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.o_custkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank <= 10
)
SELECT 
    r.r_name AS region,
    SUM(tp.revenue) AS total_revenue
FROM 
    TopRevenues tp
JOIN 
    region r ON tp.r_name = r.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
