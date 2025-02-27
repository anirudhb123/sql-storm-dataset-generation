WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND 
        o.o_orderdate < DATE '2023-12-31'
),
top_orders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        s.s_name,
        c.c_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        ranked_orders ro
    JOIN 
        lineitem l ON ro.o_orderkey = l.l_orderkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        customer c ON ro.o_custkey = c.c_custkey
    WHERE 
        ro.order_rank <= 10 
    GROUP BY 
        ro.o_orderkey, ro.o_orderdate, ro.o_totalprice, s.s_name, c.c_name
),
average_prices AS (
    SELECT 
        AVG(o.o_totalprice) AS avg_totalprice,
        COUNT(*) AS order_count
    FROM 
        top_orders o
),
order_details AS (
    SELECT 
        t.o_orderkey,
        t.o_orderdate,
        t.o_totalprice,
        t.s_name AS supplier_name,
        t.c_name AS customer_name,
        t.total_quantity,
        a.avg_totalprice,
        a.order_count
    FROM 
        top_orders t
    CROSS JOIN 
        average_prices a
)
SELECT 
    od.o_orderkey,
    od.o_orderdate,
    od.o_totalprice,
    od.supplier_name,
    od.customer_name,
    od.total_quantity,
    od.avg_totalprice,
    od.order_count,
    CASE 
        WHEN od.o_totalprice > od.avg_totalprice THEN 'Above Average' 
        ELSE 'Below Average' 
    END AS price_comparison
FROM 
    order_details od
ORDER BY 
    od.o_orderdate DESC, od.o_totalprice DESC;
