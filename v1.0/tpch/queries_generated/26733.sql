WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity, 
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Available Quantity: ', ps.ps_availqty) AS supplier_part_info
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
        o.o_totalprice AS total_price,
        o.o_orderstatus AS order_status,
        CONCAT('Customer: ', c.c_name, ', Order Key: ', o.o_orderkey, ', Total Price: ', o.o_totalprice) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    sp.supplier_part_info, 
    co.customer_order_info,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = co.order_key) AS line_item_count
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.available_quantity > 0
WHERE 
    sp.supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    co.total_price DESC, 
    sp.available_quantity DESC
LIMIT 10;
