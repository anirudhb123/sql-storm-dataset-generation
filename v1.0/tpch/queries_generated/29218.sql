WITH SupplierPartInfo AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Available Quantity: ', CAST(ps.ps_availqty AS varchar), ', Supply Cost: $', CAST(ps.ps_supplycost AS decimal(12, 2))) AS composite_info
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderInfo AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        o.o_totalprice AS total_price,
        o.o_orderdate AS order_date,
        CONCAT('Customer: ', c.c_name, ', Order Key: ', CAST(o.o_orderkey AS varchar), ', Total Price: $', CAST(o.o_totalprice AS decimal(12, 2)), ', Order Date: ', CAST(o.o_orderdate AS varchar)) AS composite_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    spi.supplier_name,
    coi.customer_name,
    spi.composite_info AS supplier_info,
    coi.composite_info AS customer_info,
    COUNT(*) AS combinations_count
FROM 
    SupplierPartInfo spi
CROSS JOIN 
    CustomerOrderInfo coi
GROUP BY 
    spi.supplier_name, coi.customer_name, spi.composite_info, coi.composite_info
ORDER BY 
    combinations_count DESC;
