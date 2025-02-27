WITH RECURSIVE customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(o.o_totalprice) as total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) as order_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        SUM(o.o_totalprice) > 1000
),
top_customers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COALESCE(AVG(o.o_totalprice), 0) as avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    ORDER BY 
        avg_order_value DESC
    LIMIT 5
),
part_supplier_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) as total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) as total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
supplier_summary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) as total_supply_cost,
        COUNT(ps.ps_partkey) as part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        COUNT(ps.ps_partkey) > 10
)

SELECT 
    cu.c_name as customer_name,
    cu.total_spent as total_spent,
    tc.avg_order_value as average_order_value,
    ps.p_name as part_name,
    ps.total_available as part_availability,
    ss.s_name as supplier_name,
    ss.total_supply_cost as supplier_total_cost
FROM 
    customer_orders cu
JOIN 
    top_customers tc ON cu.c_custkey = tc.c_custkey
JOIN 
    part_supplier_info ps ON ps.total_available > 50
LEFT JOIN 
    supplier_summary ss ON ss.part_count > 20
WHERE 
    (cu.total_spent > 5000 OR tc.avg_order_value > 300)
    AND (ss.total_supply_cost IS NOT NULL OR ss.total_supply_cost > 10000)
ORDER BY 
    cu.total_spent DESC, 
    ss.total_supply_cost ASC;
