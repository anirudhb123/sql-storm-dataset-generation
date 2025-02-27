WITH SupplierPartDetails AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with a cost of ', CAST(ps.ps_supplycost AS CHAR), ' and availability of ', CAST(ps.ps_availqty AS CHAR), '.') AS detailed_info
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
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        CONCAT(c.c_name, ' has an order number ', CAST(o.o_orderkey AS CHAR), ' with a total of ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS CHAR), '.') AS order_summary
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_name, o.o_orderkey
)
SELECT 
    spd.supplier_name,
    spd.part_name,
    spd.available_quantity,
    spd.supply_cost,
    spd.detailed_info,
    cod.customer_name,
    cod.order_number,
    cod.order_total,
    cod.order_summary
FROM 
    SupplierPartDetails spd
LEFT JOIN 
    CustomerOrderDetails cod ON spd.available_quantity > 0
ORDER BY 
    spd.supplier_name, cod.order_total DESC;
