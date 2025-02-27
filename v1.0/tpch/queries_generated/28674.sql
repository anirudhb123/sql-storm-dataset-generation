WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        CONCAT(s.s_address, ' (', s.s_phone, ')') AS supplier_info,
        p.p_name AS part_name,
        p.p_retailprice,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT('Part: ', p.p_name, ', Supply Cost: ', ps.ps_supplycost, ', Available Qty: ', ps.ps_availqty) AS part_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        ps.ps_availqty > 100
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT('Order Key: ', o.o_orderkey, ', Total Price: ', o.o_totalprice, ', Status: ', o.o_orderstatus) AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
)
SELECT 
    sp.supplier_name,
    sp.supplier_info,
    sp.part_name,
    sp.p_retailprice,
    sp.part_details,
    co.customer_name,
    co.order_details
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.p_retailprice > co.o_totalprice
ORDER BY 
    sp.supplier_name, co.customer_name;
