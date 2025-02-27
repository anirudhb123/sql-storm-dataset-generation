WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
        r.r_name AS region_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY 
        o.o_orderkey, c.c_name, r.r_name
),
TopCustomers AS (
    SELECT 
        revenue_rank,
        c_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        revenue_rank <= 10
)
SELECT 
    t.region_name,
    COUNT(*) AS number_of_top_customers,
    SUM(ROUND(total_revenue, 2)) AS total_revenue_sum
FROM 
    TopCustomers t
GROUP BY 
    t.region_name
ORDER BY 
    total_revenue_sum DESC;
