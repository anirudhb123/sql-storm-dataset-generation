WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY 
        o.o_orderkey, c.c_name, c.c_nationkey
),
TopCustomers AS (
    SELECT 
        r.r_name,
        ro.c_name,
        ro.revenue
    FROM 
        RankedOrders ro 
    JOIN 
        nation n ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_name = ro.c_name)
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ro.rank <= 5
)
SELECT 
    r.r_name, 
    SUM(tc.revenue) AS total_revenue
FROM 
    TopCustomers tc
JOIN 
    region r ON tc.r_name = r.r_name
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;