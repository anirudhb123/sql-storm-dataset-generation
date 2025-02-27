
WITH PartSupplierSummary AS (
    SELECT 
        p.p_name,
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_suppkey) AS total_suppliers,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(CONCAT(s.s_address, ' - ', s.s_phone), '; ') AS supplier_details
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        p.p_name, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date,
        STRING_AGG(CONCAT(o.o_orderstatus, ' - ', o.o_orderpriority), '; ') AS order_statuses
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    ps.p_name,
    ps.total_suppliers,
    ps.total_available_quantity,
    ps.average_supply_cost,
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    cs.last_order_date,
    ps.supplier_details
FROM 
    PartSupplierSummary ps
JOIN 
    CustomerOrderSummary cs ON ps.total_suppliers > 1
ORDER BY 
    ps.average_supply_cost DESC, 
    cs.total_spent DESC;
