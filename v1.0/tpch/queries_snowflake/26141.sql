
WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        p.p_name,
        p.p_container,
        ps.ps_availqty,
        ps.ps_supplycost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' in ', p.p_container) AS supply_details,
        p.p_partkey
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
        o.o_orderdate,
        CONCAT(c.c_name, ' ordered with order key ', o.o_orderkey, ' on ', o.o_orderdate) AS customer_order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),

StringBenchmark AS (
    SELECT 
        sp.s_name,
        co.c_name,
        LENGTH(sp.supply_details) AS supply_details_length,
        LENGTH(co.customer_order_details) AS customer_order_details_length,
        LOWER(sp.supply_details) AS supply_details_lower,
        UPPER(co.customer_order_details) AS customer_order_details_upper
    FROM 
        SupplierParts sp
    JOIN 
        CustomerOrders co ON sp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey LIMIT 1) 
    ORDER BY 
        supply_details_length DESC, customer_order_details_length DESC
)

SELECT 
    s_name,
    c_name,
    supply_details_length, 
    customer_order_details_length,
    supply_details_lower,
    customer_order_details_upper
FROM 
    StringBenchmark
WHERE 
    supply_details_length > 50 
    AND customer_order_details_length > 50
FETCH FIRST 100 ROWS ONLY;
