WITH SupplierPart AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Qty: ', ps.ps_availqty, ', Cost: ', ROUND(ps.ps_supplycost, 2)) AS detailed_description
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
        CONCAT('Customer: ', c.c_name, ', Order: ', o.o_orderkey, ', Date: ', o.o_orderdate, ', Total: ', ROUND(o.o_totalprice, 2)) AS order_description
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey AS order_key,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice) AS total_extended_price,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    SP.supplier_name,
    SP.part_name,
    SP.available_quantity,
    SP.supply_cost,
    SP.detailed_description,
    CO.order_key,
    CO.order_date,
    CO.total_price,
    CO.order_description,
    LID.total_quantity,
    LID.total_extended_price,
    LID.distinct_parts
FROM 
    SupplierPart SP
JOIN 
    CustomerOrders CO ON SP.available_quantity > 10
LEFT JOIN 
    LineItemDetails LID ON CO.order_key = LID.order_key
ORDER BY 
    SP.supplier_name, CO.order_date;
