WITH supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
product_lines AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(l.l_quantity) AS total_quantity_sold,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        part p ON l.l_partkey = p.p_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    ss.s_name,
    pl.p_name,
    pl.total_quantity_sold,
    pl.total_revenue,
    CASE
        WHEN ss.total_available_quantity > 1000 THEN 'High Availability'
        WHEN ss.total_available_quantity BETWEEN 500 AND 1000 THEN 'Medium Availability'
        ELSE 'Low Availability'
    END AS availability_status,
    cs.total_spent
FROM 
    customer_orders cs
JOIN 
    supplier_summary ss ON cs.total_orders > 5
JOIN 
    product_lines pl ON pl.total_quantity_sold > 0
WHERE 
    cs.order_rank <= 10 
    AND ss.part_count > 3
ORDER BY 
    cs.total_spent DESC,
    pl.total_revenue DESC;
