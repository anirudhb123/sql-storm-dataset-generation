WITH RankedOrders AS (
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
        o.o_orderdate >= DATE '2023-01-01' -- Filter for the current year
    GROUP BY 
        o.o_orderkey, 
        o.o_orderdate
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey, 
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    cr.customer_revenue
FROM 
    customer c
JOIN 
    CustomerRevenue cr ON c.c_custkey = cr.c_custkey
WHERE 
    cr.customer_revenue > 10000 -- Only include customers with a significant amount of revenue
ORDER BY 
    cr.customer_revenue DESC 
LIMIT 10; -- Get the top 10 customers
