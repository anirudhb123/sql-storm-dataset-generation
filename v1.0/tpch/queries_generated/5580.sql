WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) as revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
), TopCustomers AS (
    SELECT 
        r.r_name, 
        SUM(ro.total_revenue) AS nation_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name,
    r.nation_revenue,
    RANK() OVER (ORDER BY r.nation_revenue DESC) as revenue_rank
FROM 
    TopCustomers r
ORDER BY 
    revenue_rank;
