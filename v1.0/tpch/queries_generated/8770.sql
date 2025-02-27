WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2023-12-31'
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.customer_name,
        ro.c_acctbal
    FROM 
        ranked_orders ro
    WHERE 
        ro.order_rank <= 5
),
order_details AS (
    SELECT 
        to.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_linenumber) AS total_items,
        AVG(l.l_quantity) AS avg_quantity_per_item
    FROM 
        top_orders to
    JOIN 
        lineitem l ON to.o_orderkey = l.l_orderkey
    GROUP BY 
        to.o_orderkey
)
SELECT 
    to.customer_name,
    od.o_orderkey,
    od.total_revenue,
    od.total_items,
    od.avg_quantity_per_item
FROM 
    top_orders to
JOIN 
    order_details od ON to.o_orderkey = od.o_orderkey
ORDER BY 
    od.total_revenue DESC;
