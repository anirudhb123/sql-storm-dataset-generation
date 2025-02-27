WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ps.ps_comment AS part_supplier_comment
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
        o.o_orderstatus AS order_status,
        o.o_comment AS order_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
StringBenchmark AS (
    SELECT 
        sp.supplier_name,
        sp.part_name,
        COALESCE(NULLIF(LEFT(sp.part_supplier_comment, 20), ''), 'No Comment') AS short_comment,
        STRING_AGG(DISTINCT co.customer_name, ', ') AS customers,
        COUNT(co.order_key) AS order_count,
        SUM(co.total_price) AS total_income
    FROM 
        SupplierParts sp
    LEFT JOIN 
        CustomerOrders co ON sp.part_name LIKE '%' || co.order_comment || '%'
    GROUP BY 
        sp.supplier_name, sp.part_name, short_comment
)
SELECT 
    supplier_name, 
    part_name, 
    short_comment,
    customers,
    order_count,
    total_income
FROM 
    StringBenchmark
ORDER BY 
    supplier_name, part_name;
