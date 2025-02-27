WITH SupplierCosts AS (
    SELECT 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
), CustomerOrders AS (
    SELECT 
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_name
), SKUDetails AS (
    SELECT 
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        AVG(l.l_discount) AS avg_discount
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_name
), ResultSet AS (
    SELECT 
        sc.s_name AS supplier_name,
        co.c_name AS customer_name,
        sku.p_name AS part_name,
        sc.total_supply_cost,
        co.total_order_value,
        sku.order_count,
        sku.avg_discount
    FROM 
        SupplierCosts sc
    CROSS JOIN 
        CustomerOrders co
    JOIN 
        SKUDetails sku ON sc.total_supply_cost > 1000 AND co.total_order_value > 5000
)
SELECT 
    supplier_name,
    customer_name,
    part_name,
    total_supply_cost,
    total_order_value,
    order_count,
    avg_discount
FROM 
    ResultSet
ORDER BY 
    total_supply_cost DESC, 
    total_order_value DESC;
