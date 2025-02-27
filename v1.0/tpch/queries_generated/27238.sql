WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with qty ', CAST(ps.ps_availqty AS VARCHAR), ' at cost ', CAST(ps.ps_supplycost AS VARCHAR(12,2))) AS supply_info
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
        o.o_orderdate AS order_date,
        o.o_totalprice AS total_price,
        CONCAT('Order ', CAST(o.o_orderkey AS VARCHAR), ' by ', c.c_name, ' on ', CAST(o.o_orderdate AS VARCHAR), ' for total price ', CAST(o.o_totalprice AS VARCHAR(12,2))) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    sp.supply_cost,
    co.customer_name,
    co.order_key,
    co.order_date,
    co.total_price,
    sp.supply_info,
    co.order_info
FROM 
    SupplierParts sp
JOIN 
    lineitem l ON sp.part_name = (SELECT p_name FROM part WHERE p_partkey = l.l_partkey)
JOIN 
    CustomerOrders co ON co.order_key = l.l_orderkey
WHERE 
    sp.available_quantity > 100
ORDER BY 
    sp.supplier_name, co.order_date DESC;
