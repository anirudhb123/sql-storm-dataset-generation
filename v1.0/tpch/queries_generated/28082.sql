WITH supply_info AS (
    SELECT 
        s.s_suppkey AS supplier_id,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        CONCAT('Supplier ', s.s_name, ' offers part ', p.p_name, ' at a cost of ', CAST(ps.ps_supplycost AS VARCHAR(12)), ' with quantity ', CAST(ps.ps_availqty AS VARCHAR(10))) AS supply_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
customer_orders AS (
    SELECT 
        c.c_custkey AS customer_id,
        c.c_name AS customer_name,
        o.o_orderkey AS order_id,
        o.o_orderdate AS order_date,
        CONCAT('Customer ', c.c_name, ' made an order with ID ', CAST(o.o_orderkey AS VARCHAR(10)), ' on ', CAST(o.o_orderdate AS VARCHAR(10))) AS order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    si.supplier_id,
    si.supplier_name,
    si.part_name,
    si.supply_cost,
    si.available_quantity,
    si.supply_details,
    co.customer_id,
    co.customer_name,
    co.order_id,
    co.order_date,
    co.order_details
FROM 
    supply_info si
LEFT JOIN 
    customer_orders co ON si.available_quantity > 0
ORDER BY 
    si.supplier_name, co.order_date DESC
LIMIT 100;
