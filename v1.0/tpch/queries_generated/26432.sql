WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        COALESCE(CONCAT(s.s_name, ' supplies ', p.p_name), 'Unknown part') AS supplier_part_info
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        COALESCE(CONCAT(c.c_name, ' has spent a total of ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS varchar), ' on orders.'), 'Unknown customer') AS customer_order_info
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
    sp.supplier_name, 
    sp.part_name, 
    sp.available_quantity, 
    sp.supply_cost, 
    co.customer_name, 
    co.total_spent, 
    co.order_count,
    CONCAT(sp.supplier_part_info, ' | ', co.customer_order_info) AS combined_info
FROM 
    SupplierParts sp
LEFT JOIN 
    CustomerOrders co ON TRUE
ORDER BY 
    total_spent DESC, 
    available_quantity DESC
LIMIT 50;
