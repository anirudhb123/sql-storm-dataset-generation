WITH RECURSIVE price_cte AS (
    SELECT 
        ps_partkey, 
        SUM(ps_supplycost * ps_availqty) AS total_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
),
ranked_suppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        p.p_size > 10
),
final_selection AS (
    SELECT 
        c.c_name,
        co.total_spent,
        p.p_name,
        pc.total_cost
    FROM 
        customer_orders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    LEFT JOIN 
        lineitem l ON c.c_custkey = l.l_orderkey
    LEFT JOIN 
        price_cte pc ON l.l_partkey = pc.ps_partkey
    JOIN 
        ranked_suppliers rs ON rs.s_suppkey = l.l_suppkey
    WHERE 
        rs.supplier_rank = 1
)
SELECT 
    f.c_name,
    f.total_spent,
    f.p_name,
    COALESCE(f.total_cost, 0) AS total_cost,
    CASE 
        WHEN f.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM 
    final_selection f
WHERE 
    f.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
ORDER BY 
    f.total_spent DESC;
