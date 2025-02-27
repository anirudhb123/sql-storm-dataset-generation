WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
top_sales AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        r.total_sales
    FROM 
        ranked_orders r
    JOIN 
        orders o ON r.o_orderkey = o.o_orderkey
    WHERE 
        r.sales_rank <= 5
),
supplier_summary AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
final_report AS (
    SELECT 
        c.c_name,
        cs.order_count,
        cs.total_spent,
        ss.total_available,
        ss.avg_supply_cost,
        ts.total_sales
    FROM 
        customer_orders cs
    LEFT JOIN 
        customer c ON cs.c_custkey = c.c_custkey
    LEFT JOIN 
        supplier_summary ss ON cs.order_count > 0
    LEFT JOIN 
        top_sales ts ON cs.order_count = 1
)
SELECT 
    f.c_name,
    COALESCE(f.order_count, 0) AS order_count,
    COALESCE(f.total_spent, 0) AS total_spent,
    COALESCE(f.total_available, 0) AS total_available,
    COALESCE(f.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(f.total_sales, 0) AS total_sales,
    CASE 
        WHEN f.total_spent > 1000 THEN 'High Value'
        WHEN f.total_spent > 500 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    final_report f
ORDER BY 
    f.total_spent DESC;
