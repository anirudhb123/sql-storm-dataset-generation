WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        c.c_name,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, c.c_name, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        rc.n_name,
        rc.total_revenue,
        rc.o_orderkey,
        rc.c_name,
        rc.o_orderdate
    FROM 
        RankedOrders rc
    JOIN 
        nation n ON rc.c_nationkey = n.n_nationkey
    WHERE 
        rc.revenue_rank <= 5
)
SELECT 
    rc.n_name AS Nation,
    COUNT(*) AS Top_Customer_Count,
    AVG(rc.total_revenue) AS Avg_Revenue,
    MAX(rc.total_revenue) AS Max_Revenue,
    MIN(rc.total_revenue) AS Min_Revenue
FROM 
    TopCustomers rc
GROUP BY 
    rc.n_name
ORDER BY 
    Top_Customer_Count DESC, Avg_Revenue DESC;
