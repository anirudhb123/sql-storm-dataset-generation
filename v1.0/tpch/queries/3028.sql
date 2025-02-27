
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
        o.o_orderstatus = 'O' 
        AND l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region,
        c.c_name AS customer_name,
        ro.total_revenue
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON c.c_nationkey = (SELECT DISTINCT c_nationkey FROM customer WHERE c_name = ro.c_name)
    JOIN 
        nation n ON n.n_nationkey = c.c_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.revenue_rank <= 5
)
SELECT 
    t.region,
    COUNT(t.customer_name) AS top_customers_count,
    AVG(t.total_revenue) AS avg_revenue_per_top_customer
FROM 
    TopCustomers t
GROUP BY 
    t.region
ORDER BY 
    avg_revenue_per_top_customer DESC;
