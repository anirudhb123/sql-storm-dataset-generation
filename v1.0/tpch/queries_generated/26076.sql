WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with availability of ', ps.ps_availqty, ' units') AS supply_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        CONCAT('Order ', o.o_orderkey, ' for customer ', c.c_name, ' total price is ', o.o_totalprice) AS order_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    sp.supplier_comment,
    co.order_comment
FROM 
    SupplierParts sp
LEFT JOIN 
    CustomerOrders co ON sp.s_suppkey = co.c_custkey
WHERE 
    sp.ps_supplycost > 100.00 
ORDER BY 
    sp.s_name ASC, co.o_orderkey DESC;
