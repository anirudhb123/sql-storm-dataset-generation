WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with available quantity of ', CAST(ps.ps_availqty AS VARCHAR), ' at cost ', CAST(ps.ps_supplycost AS VARCHAR)) AS supplier_part_info
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
        o.o_orderkey AS order_id,
        o.o_orderdate AS order_date,
        CONCAT(c.c_name, ' placed order #', CAST(o.o_orderkey AS VARCHAR), ' on ', CAST(o.o_orderdate AS VARCHAR)) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
CombinedInfo AS (
    SELECT 
        sp.supplier_part_info,
        co.customer_order_info
    FROM 
        SupplierParts sp
    CROSS JOIN 
        CustomerOrders co
)
SELECT 
    supplier_part_info,
    customer_order_info,
    LENGTH(supplier_part_info) AS supplier_part_info_length,
    LENGTH(customer_order_info) AS customer_order_info_length
FROM 
    CombinedInfo
ORDER BY 
    supplier_part_info_length DESC, customer_order_info_length DESC
LIMIT 50;
