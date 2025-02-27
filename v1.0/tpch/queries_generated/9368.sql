WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
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
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        t.c_name AS customer_name,
        t.total_revenue,
        t.o_orderdate
    FROM 
        RankedOrders t
    JOIN 
        nation n ON t.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        t.revenue_rank <= 5
)
SELECT 
    region_name,
    customer_name,
    SUM(total_revenue) AS total_revenue_sum,
    COUNT(DISTINCT o_orderdate) AS order_dates_count
FROM 
    TopCustomers
GROUP BY 
    region_name, customer_name
ORDER BY 
    total_revenue_sum DESC
LIMIT 10;
