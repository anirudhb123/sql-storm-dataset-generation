WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY DATE_TRUNC('month', o.o_orderdate) ORDER BY o.o_totalprice DESC) as order_rank
    FROM 
        orders o 
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate < DATE '2023-01-01'
), 
top_orders AS (
    SELECT 
        order_date,
        o_orderkey,
        o_totalprice,
        c_name,
        c_acctbal
    FROM 
        ranked_orders
    WHERE 
        order_rank <= 5
), 
order_details AS (
    SELECT 
        to.order_date,
        to.o_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        SUM(li.l_quantity) AS total_quantity,
        COUNT(DISTINCT li.l_suppkey) AS unique_suppliers
    FROM 
        top_orders to
    JOIN 
        lineitem li ON to.o_orderkey = li.l_orderkey
    GROUP BY 
        to.order_date, to.o_orderkey
)
SELECT 
    o.order_date,
    COUNT(o.o_orderkey) AS num_orders,
    SUM(o.total_sales) AS total_revenue,
    AVG(o.total_quantity) AS avg_quantity_per_order,
    SUM(o.unique_suppliers) AS total_unique_suppliers
FROM 
    order_details o
GROUP BY 
    o.order_date
ORDER BY 
    o.order_date;
