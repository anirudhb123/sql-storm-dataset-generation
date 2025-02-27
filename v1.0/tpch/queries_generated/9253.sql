WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2021-01-01' AND o.o_orderdate < DATE '2022-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopCustomer AS (
    SELECT 
        r.r_name AS region_name,
        SUM(ro.total_revenue) AS total_revenue_by_region
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    region_name,
    total_revenue_by_region
FROM 
    TopCustomer
ORDER BY 
    total_revenue_by_region DESC;
