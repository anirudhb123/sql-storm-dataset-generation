WITH SupplierPerformance AS (
    SELECT 
        s.s_name AS supplier_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(ps.ps_supplycost) AS avg_cost_per_part,
        STRING_AGG(DISTINCT SUBSTRING(p.p_comment, 1, 10), ', ') AS part_comments_snippet
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_name AS customer_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(DISTINCT o.o_comment, '; ') AS order_comments_snippet
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_name
)
SELECT 
    sp.supplier_name,
    sp.total_parts_supplied,
    sp.total_supply_value,
    sp.avg_cost_per_part,
    co.customer_name,
    co.total_orders,
    co.total_spent,
    co.order_comments_snippet
FROM 
    SupplierPerformance sp
JOIN 
    CustomerOrders co ON sp.total_supply_value > co.total_spent
ORDER BY 
    sp.total_supply_value DESC, co.total_spent DESC;
