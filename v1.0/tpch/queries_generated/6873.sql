WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        c.c_name AS customer_name,
        ro.total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank = 1
)
SELECT 
    region_name,
    COUNT(customer_name) AS number_of_top_customers,
    SUM(total_revenue) AS total_revenue_from_top_customers
FROM 
    TopCustomers
GROUP BY 
    region_name
ORDER BY 
    total_revenue_from_top_customers DESC;
