WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' at a cost of ', CAST(ps.ps_supplycost AS varchar(12)), ' with availability of ', CAST(ps.ps_availqty AS varchar(10))) AS supplier_part_info
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
        CONCAT(c.c_name, ' made an order with key ', CAST(o.o_orderkey AS varchar(10)), ' totaling ', CAST(o.o_totalprice AS decimal(12, 2))) AS customer_order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
BenchmarkData AS (
    SELECT 
        sp.supplier_part_info,
        co.customer_order_info,
        LENGTH(sp.supplier_part_info) AS supplier_info_length,
        LENGTH(co.customer_order_info) AS customer_order_info_length
    FROM 
        SupplierParts sp
    JOIN 
        CustomerOrders co ON sp.available_quantity > 0
)
SELECT 
    AVG(supplier_info_length) AS avg_supplier_info_length, 
    AVG(customer_order_info_length) AS avg_customer_order_info_length,
    COUNT(*) AS total_records
FROM 
    BenchmarkData;
