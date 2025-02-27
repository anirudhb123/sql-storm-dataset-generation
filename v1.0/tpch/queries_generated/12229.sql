WITH total_sales AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS sales
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l_orderkey
), 
top_orders AS (
    SELECT 
        o_o.orderkey,
        t.sales
    FROM 
        orders o
    JOIN 
        total_sales t ON o.o_orderkey = t.l_orderkey
    ORDER BY 
        t.sales DESC
    LIMIT 10
)
SELECT 
    o.o_orderkey,
    o.o_orderstatus,
    o.o_totalprice,
    o.o_orderdate,
    o.o_orderpriority,
    t.sales
FROM 
    orders o
JOIN 
    top_orders t ON o.o_orderkey = t.orderkey;
