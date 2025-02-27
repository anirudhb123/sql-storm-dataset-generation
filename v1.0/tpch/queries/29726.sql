
WITH customer_order_summary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT r.r_name, ', ') AS regions
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        supplier s ON o.o_orderkey % s.s_suppkey = 0
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_orders,
        cs.total_spent
    FROM 
        customer c
    JOIN 
        customer_order_summary cs ON c.c_custkey = cs.c_custkey
    WHERE 
        cs.total_spent > (
            SELECT AVG(total_spent) FROM customer_order_summary
        )
)
SELECT 
    hvc.c_name,
    hvc.total_orders,
    hvc.total_spent,
    REPLACE(hvc.c_name, ' ', '_') AS name_with_underscores,
    UPPER(hvc.c_name) AS name_uppercase
FROM 
    high_value_customers hvc
ORDER BY 
    hvc.total_spent DESC;
