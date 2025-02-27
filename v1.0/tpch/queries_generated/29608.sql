WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_desc,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_name
), 
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    sp.supplier_part_desc,
    sp.total_available_quantity,
    sp.total_supply_cost,
    co.total_orders,
    co.avg_order_value
FROM 
    SupplierPartInfo sp
JOIN 
    CustomerOrderInfo co ON sp.s_suppkey = (SELECT s.s_suppkey FROM supplier s WHERE s.s_name LIKE '%' || SUBSTR(co.c_name, 1, 5) || '%') 
    ORDER BY s.s_suppkey LIMIT 1)
WHERE 
    sp.total_available_quantity > 100
ORDER BY 
    sp.total_supply_cost DESC, co.avg_order_value ASC;
