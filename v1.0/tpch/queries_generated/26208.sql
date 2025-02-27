WITH supplier_parts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty, ' units and a supply cost of ', FORMAT(ps.ps_supplycost, 2)) AS detailed_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        CONCAT(c.c_name, ' has placed ', COUNT(o.o_orderkey), ' orders totaling $', FORMAT(SUM(o.o_totalprice), 2)) AS customer_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    sp.supplier_name,
    sp.detailed_info,
    co.customer_name,
    co.total_orders,
    co.total_spent,
    co.customer_info
FROM 
    supplier_parts sp
JOIN 
    customer_orders co ON sp.available_quantity > 50
ORDER BY 
    sp.supply_cost DESC, co.total_spent DESC;
