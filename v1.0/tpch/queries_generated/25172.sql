WITH SupplierParts AS (
    SELECT 
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(CAST(ps.ps_availqty AS VARCHAR), ' units of ', p.p_name, ' supplied by ', s.s_name) AS supply_detail
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
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        CONCAT(c.c_name, ' has made ', COUNT(o.o_orderkey), ' orders totaling ', SUM(o.o_totalprice), ' dollars.') AS order_summary
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
    sp.available_quantity,
    sp.supply_cost,
    sp.supply_detail,
    co.customer_name,
    co.order_count,
    co.total_spent,
    co.order_summary
FROM 
    SupplierParts sp
JOIN 
    CustomerOrders co ON sp.supply_cost < (co.total_spent / NULLIF(co.order_count, 0))
ORDER BY 
    sp.available_quantity DESC, co.total_spent DESC
LIMIT 100;
