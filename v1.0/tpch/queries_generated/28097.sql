WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name, 
        p.p_name AS part_name, 
        COUNT(*) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with quantity ', ps.ps_availqty) AS part_supply_details
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name, p.p_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(o.o_orderstatus, ', ') AS order_statuses,
        CONCAT(c.c_name, ' placed ', COUNT(o.o_orderkey), ' orders totaling $', SUM(o.o_totalprice)) AS customer_order_details
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    sp.supplier_name, 
    sp.part_name, 
    sp.total_parts, 
    sp.total_available_quantity, 
    sp.total_supply_cost, 
    co.customer_name, 
    co.total_orders, 
    co.total_spent, 
    co.order_statuses,
    CONCAT(sp.part_supply_details, '; ', co.customer_order_details) AS detailed_report
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.total_parts > 0
ORDER BY 
    sp.total_available_quantity DESC, co.total_spent DESC;
