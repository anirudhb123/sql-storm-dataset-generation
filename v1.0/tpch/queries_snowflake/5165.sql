
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_name, 
        SUM(ro.total_revenue) AS total_spent
    FROM 
        RankedOrders ro
    JOIN 
        customer c ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
    WHERE 
        ro.revenue_rank <= 10
    GROUP BY 
        c.c_name
)
SELECT 
    tc.c_name, 
    tc.total_spent, 
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS number_of_suppliers
FROM 
    TopCustomers tc
JOIN 
    supplier s ON tc.c_name = s.s_name
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    tc.total_spent > 10000
GROUP BY 
    tc.c_name, tc.total_spent, r.r_name
ORDER BY 
    tc.total_spent DESC;
