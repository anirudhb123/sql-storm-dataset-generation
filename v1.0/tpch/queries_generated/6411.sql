WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
),
CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(ro.total_revenue) AS customer_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        RankedOrders ro ON o.o_orderkey = ro.o_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        cs.c_custkey,
        cs.c_name,
        cs.customer_revenue,
        RANK() OVER (ORDER BY cs.customer_revenue DESC) AS rank
    FROM 
        CustomerSales cs
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.customer_revenue,
    r.r_name AS region_name
FROM 
    TopCustomers tc
JOIN 
    supplier s ON s.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
JOIN 
    region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.customer_revenue DESC;
