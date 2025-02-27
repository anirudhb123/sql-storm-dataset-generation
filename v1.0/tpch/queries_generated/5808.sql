WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ro.order_rank
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
),
OrderDetails AS (
    SELECT 
        to.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_items
    FROM 
        TopOrders to
    JOIN 
        lineitem l ON to.o_orderkey = l.l_orderkey
    GROUP BY 
        to.o_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    od.total_revenue,
    od.total_items
FROM 
    TopOrders to
JOIN 
    OrderDetails od ON to.o_orderkey = od.o_orderkey
ORDER BY 
    od.total_revenue DESC, to.o_totalprice DESC;
