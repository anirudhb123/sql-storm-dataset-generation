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
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSpending AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cs.c_custkey, 
        cs.c_name, 
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerSpending cs
)
SELECT 
    ro.o_orderkey, 
    ro.o_orderdate, 
    tc.c_custkey, 
    tc.c_name, 
    tc.total_spent, 
    ro.total_revenue
FROM 
    RankedOrders ro
JOIN 
    TopCustomers tc ON ro.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = tc.c_custkey LIMIT 1)
WHERE 
    ro.revenue_rank <= 10 
    AND tc.spending_rank <= 10
ORDER BY 
    ro.o_orderdate, 
    ro.total_revenue DESC;