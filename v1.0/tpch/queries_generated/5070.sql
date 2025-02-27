WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopNations AS (
    SELECT 
        n.n_name,
        SUM(r.total_revenue) AS nation_revenue
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.revenue_rank <= 10
    GROUP BY 
        n.n_name
)
SELECT 
    n.r_name AS region_name,
    SUM(t.nation_revenue) AS total_region_revenue
FROM 
    region n
JOIN 
    nation na ON n.r_regionkey = na.n_regionkey
JOIN 
    TopNations t ON na.n_name = t.n_name
GROUP BY 
    n.r_name
ORDER BY 
    total_region_revenue DESC;
