WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate <= DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.revenue
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),

CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(to.revenue) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        TopOrders to ON o.o_orderkey = to.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
)

SELECT 
    cr.c_custkey,
    cr.c_name,
    cr.total_revenue,
    r.r_name AS region_name
FROM 
    CustomerRevenue cr
JOIN 
    nation n ON cr.c_custkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    cr.total_revenue > 10000
ORDER BY 
    cr.total_revenue DESC;
