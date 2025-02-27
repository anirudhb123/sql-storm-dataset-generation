
WITH SupplierPart AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        CONCAT('Supplier: ', s.s_name, ' supplies part: ', p.p_name, ' at a price of: ', ps.ps_supplycost) AS supply_info
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
        o.o_orderkey AS order_id, 
        CONCAT('Order ID: ', o.o_orderkey, ' placed by: ', c.c_name, ' on date: ', o.o_orderdate) AS order_info
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
), 
DetailedSummary AS (
    SELECT 
        sp.supply_info, 
        co.order_info
    FROM 
        SupplierPart sp
    JOIN 
        lineitem l ON l.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = SPLIT_PART(sp.part_name, ' ', 1) LIMIT 1)
    JOIN 
        CustomerOrders co ON l.l_orderkey = co.order_id
)
SELECT 
    d.supply_info, 
    d.order_info, 
    LENGTH(d.supply_info) AS supply_info_length, 
    LENGTH(d.order_info) AS order_info_length
FROM 
    DetailedSummary d
WHERE 
    d.order_info LIKE '%placed%'
ORDER BY 
    supply_info_length DESC, 
    order_info_length DESC
LIMIT 50;
