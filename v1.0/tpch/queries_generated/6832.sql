WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.order_value
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 10
)
SELECT 
    c.c_name AS customer_name,
    c.c_address AS customer_address,
    to.o_orderkey,
    to.o_orderdate,
    to.order_value,
    COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered,
    SUM(l.l_quantity) AS total_quantity_ordered
FROM 
    TopOrders to
JOIN 
    orders o ON to.o_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    lineitem l ON to.o_orderkey = l.l_orderkey
GROUP BY 
    c.c_name, c.c_address, to.o_orderkey, to.o_orderdate, to.order_value
ORDER BY 
    to.order_value DESC, c.c_name ASC;
