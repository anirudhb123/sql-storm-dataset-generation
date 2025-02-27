WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with cost ', CAST(ps.ps_supplycost AS VARCHAR(20)), ' and availabilty ', CAST(ps.ps_availqty AS VARCHAR(10))) AS supply_details
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
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        CONCAT(c.c_name, ' made an order with total price ', CAST(o.o_totalprice AS VARCHAR(20)), ' on ', CAST(o.o_orderdate AS VARCHAR(10))) AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
CombinedInfo AS (
    SELECT 
        sp.supplier_name,
        sp.part_name,
        sp.ps_supplycost,
        co.customer_name,
        co.order_details,
        sp.supply_details
    FROM 
        SupplierParts sp
    LEFT JOIN 
        CustomerOrders co ON sp.ps_availqty > 0  -- Assuming only available parts are considered for orders
)
SELECT 
    supplier_name,
    part_name,
    ps_supplycost,
    customer_name,
    order_details,
    supply_details
FROM 
    CombinedInfo
WHERE 
    supplier_name IS NOT NULL
ORDER BY 
    supplier_name, part_name;
