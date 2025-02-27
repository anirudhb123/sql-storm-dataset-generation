WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_brand AS part_brand,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' (Brand: ', p.p_brand, ') at a cost of $', ps.ps_supplycost) AS detailed_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_orderkey) AS line_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.part_brand,
    spd.supply_cost,
    spd.available_quantity,
    co.customer_name,
    co.order_key,
    co.total_order_value,
    co.line_count,
    CONCAT(spd.detailed_comment, ' | Order Value: $', co.total_order_value) AS full_description
FROM 
    SupplierPartDetails spd
JOIN 
    CustomerOrders co ON spd.supplier_name LIKE '%' || co.customer_name || '%' 
WHERE 
    spd.supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    co.total_order_value DESC, spd.supplier_name;
