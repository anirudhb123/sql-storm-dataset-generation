WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopNationRevenue AS (
    SELECT 
        n.n_name,
        SUM(ro.total_revenue) AS total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.c_name = c.c_name
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        ro.rnk <= 5
    GROUP BY 
        n.n_name
)
SELECT 
    n.r_name AS region,
    tn.total_revenue
FROM 
    TopNationRevenue tn
JOIN 
    region n ON tn.n_nationkey = n.r_regionkey
ORDER BY 
    tn.total_revenue DESC;
