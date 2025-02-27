WITH ranked_parts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        SUM(ps.ps_availqty) AS total_available_qty,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY SUM(ps.ps_availqty) DESC) AS part_rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
), 
customer_orders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM 
        customer_orders c
    WHERE 
        c.order_count > 5
)
SELECT 
    rc.p_partkey,
    rc.p_name,
    rc.p_mfgr,
    rc.total_available_qty,
    tc.c_name AS top_customer_name,
    tc.total_spent AS top_customer_spent
FROM 
    ranked_parts rc
FULL OUTER JOIN 
    top_customers tc ON rc.total_available_qty > 1000
WHERE 
    rc.part_rank <= 10 OR tc.customer_rank <= 10
ORDER BY 
    rc.p_partkey, tc.total_spent DESC;
