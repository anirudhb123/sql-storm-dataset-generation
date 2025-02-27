WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
), 
TopOrders AS (
    SELECT 
        r.*, 
        ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS row_num
    FROM 
        RankedOrders r
    WHERE 
        r.rank <= 10
)
SELECT 
    o.o_orderkey, 
    o.o_orderdate, 
    c.c_name AS customer_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue, 
    COUNT(DISTINCT l.l_partkey) AS unique_parts, 
    COUNT(DISTINCT o.o_orderkey) OVER () AS total_orders
FROM 
    TopOrders o 
JOIN 
    customer c ON o.o_orderkey = c.c_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
GROUP BY 
    o.o_orderkey, o.o_orderdate, c.c_name
ORDER BY 
    order_revenue DESC;
