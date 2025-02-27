WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        r.r_name AS region_name,
        DENSE_RANK() OVER (PARTITION BY r.r_regionkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopOrders AS (
    SELECT 
        o_orderkey, 
        o_orderdate,
        o_totalprice,
        c_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        price_rank <= 10
)
SELECT 
    TO_CHAR(o.o_orderdate, 'YYYY-MM') AS order_month,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    TopOrders o
GROUP BY 
    TO_CHAR(o.o_orderdate, 'YYYY-MM')
ORDER BY 
    order_month;
