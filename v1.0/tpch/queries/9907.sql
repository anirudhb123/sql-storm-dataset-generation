WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        rn.r_name AS region_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region rn ON n.n_regionkey = rn.r_regionkey
    WHERE 
        o.o_orderstatus = 'F'
),
TopOrders AS (
    SELECT 
        order_rank,
        o_orderkey,
        o_orderdate,
        o_totalprice,
        c_name,
        region_name
    FROM 
        RankedOrders
    WHERE 
        order_rank <= 5
)
SELECT 
    o.o_orderdate,
    COUNT(*) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(o.o_totalprice) AS avg_order_value,
    STRING_AGG(CONCAT(o.c_name, ': ', o.o_totalprice), ', ') AS order_details
FROM 
    TopOrders o
GROUP BY 
    o.o_orderdate
ORDER BY 
    o.o_orderdate DESC;
