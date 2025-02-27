WITH RankedOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
        AND l.l_shipmode IN ('AIR', 'TRUCK')
    GROUP BY 
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        RANK() OVER (ORDER BY SUM(total_revenue) DESC) AS revenue_rank
    FROM 
        RankedOrders ro
        JOIN customer c ON ro.c_custkey = c.c_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        revenue_rank <= 10
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue
FROM 
    TopCustomers tc
    JOIN RankedOrders ro ON tc.c_custkey = ro.c_custkey
ORDER BY 
    tc.revenue_rank, ro.o_orderdate DESC;
