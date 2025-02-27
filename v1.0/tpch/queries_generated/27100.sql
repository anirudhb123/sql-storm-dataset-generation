WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        p.p_mfgr AS manufacturer,
        p.p_type AS type,
        p.p_retailprice AS retail_price,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        ps.ps_comment AS supply_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrderDetails AS (
    SELECT 
        c.c_name AS customer_name,
        o.o_orderkey AS order_number,
        o.o_orderdate AS order_date,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.manufacturer,
    spd.type,
    spd.retail_price,
    spd.available_quantity,
    spd.supply_cost,
    spd.supply_comment,
    cod.customer_name,
    cod.order_number,
    cod.order_date,
    cod.total_value,
    cod.total_quantity
FROM 
    SupplierPartDetails spd
LEFT JOIN 
    CustomerOrderDetails cod ON spd.type LIKE '%' || cod.order_number % '' AND spd.retail_price < cod.total_value
WHERE 
    spd.available_quantity > 50
ORDER BY 
    spd.supplier_name, cod.order_date DESC
LIMIT 100;
