WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01'
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    sp.supplier_name,
    sp.part_name,
    sp.available_quantity,
    sp.supply_cost,
    co.customer_name,
    co.order_key,
    co.order_date,
    co.total_amount
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.available_quantity > 0
ORDER BY 
    co.total_amount DESC, sp.supplier_name ASC;
