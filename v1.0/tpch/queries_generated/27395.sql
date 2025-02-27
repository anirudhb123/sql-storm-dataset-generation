WITH SupplierPart AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' (Availability: ', ps.ps_availqty, ')') AS full_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), CustomerOrder AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_id,
        o.o_totalprice AS total_price,
        CONCAT('Order #', o.o_orderkey, ' by ', c.c_name, ' with total price ', o.o_totalprice) AS order_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), DetailedAnalysis AS (
    SELECT 
        sp.supplier_name,
        sp.part_name,
        co.customer_name,
        co.order_comment,
        sp.full_comment,
        sp.available_quantity,
        sp.supply_cost,
        co.total_price
    FROM 
        SupplierPart sp
    JOIN 
        lineitem l ON sp.part_name = l.l_partkey
    JOIN 
        CustomerOrder co ON l.l_orderkey = co.order_id
)
SELECT 
    supplier_name,
    part_name,
    customer_name,
    available_quantity,
    supply_cost,
    total_price,
    CONCAT(full_comment, ' | ', order_comment) AS final_comment
FROM 
    DetailedAnalysis
WHERE 
    available_quantity > 10
ORDER BY 
    total_price DESC, supply_cost ASC;
