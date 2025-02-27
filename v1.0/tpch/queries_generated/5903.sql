WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2021-01-01' AND DATE '2021-12-31'
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        c.n_name AS customer_nation
    FROM 
        ranked_orders ro
    JOIN 
        nation c ON ro.c_nationkey = c.n_nationkey
    WHERE 
        ro.order_rank <= 10
),
order_details AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue
    FROM 
        lineitem lo
    JOIN 
        top_orders to ON lo.l_orderkey = to.o_orderkey
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    to.o_orderkey,
    to.o_orderdate,
    to.customer_nation,
    od.revenue
FROM 
    top_orders to
JOIN 
    order_details od ON to.o_orderkey = od.l_orderkey
ORDER BY 
    od.revenue DESC;
