WITH RECURSIVE supplier_parts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
customer_orders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
popular_parts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity_sold DESC
    LIMIT 10
)
SELECT 
    sp.s_name AS supplier_name, 
    cp.c_name AS customer_name,
    pp.p_name AS popular_part_name,
    sp.total_parts, 
    cp.total_orders, 
    cp.total_spent, 
    pp.total_quantity_sold
FROM 
    supplier_parts sp
JOIN 
    customer_orders cp ON sp.total_parts > 0
CROSS JOIN 
    popular_parts pp
WHERE 
    cp.total_spent > 1000
ORDER BY 
    sp.total_parts DESC, cp.total_spent DESC;
