WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
)
SELECT 
    r.r_name AS region,
    SUM(RO.total_revenue) AS total_revenue_per_region
FROM 
    RankedOrders RO
JOIN 
    nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = RO.c_name LIMIT 1)
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    RO.revenue_rank <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_per_region DESC;
