WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
CustomerSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.order_count,
        cs.total_spent
    FROM 
        CustomerSummary cs
    ORDER BY 
        cs.total_spent DESC
    LIMIT 10
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    tc.c_name,
    tc.total_spent,
    tc.order_count
FROM 
    RankedOrders ro
JOIN 
    TopCustomers tc ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_name = tc.c_name))
WHERE 
    ro.order_rank <= 5
ORDER BY 
    ro.o_orderdate DESC, ro.total_revenue DESC;
