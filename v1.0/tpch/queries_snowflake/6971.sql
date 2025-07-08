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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(lo.total_revenue) AS total_customer_revenue
    FROM 
        customer c
    JOIN 
        RankedOrders lo ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lo.o_orderkey)
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_customer_revenue,
    RANK() OVER (ORDER BY tc.total_customer_revenue DESC) AS customer_rank
FROM 
    TopCustomers tc
WHERE 
    tc.total_customer_revenue > 10000
ORDER BY 
    customer_rank;