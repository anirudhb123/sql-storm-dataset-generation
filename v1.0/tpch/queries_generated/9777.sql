WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1993-01-01' AND o.o_orderdate < DATE '1995-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders ro ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        customer_revenue DESC
    LIMIT 10
)
SELECT 
    tc.c_custkey, 
    tc.c_name, 
    tc.customer_revenue, 
    COUNT(o.o_orderkey) AS order_count, 
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopCustomers tc
JOIN 
    orders o ON tc.c_custkey = o.o_custkey
GROUP BY 
    tc.c_custkey, tc.c_name, tc.customer_revenue
ORDER BY 
    tc.customer_revenue DESC;
