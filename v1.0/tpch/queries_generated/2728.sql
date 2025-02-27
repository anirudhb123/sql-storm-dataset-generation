WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemAnalysis AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS lineitem_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name AS customer_name,
    ss.s_name AS supplier_name,
    cs.total_orders,
    ss.total_available_quantity,
    ss.total_supply_cost,
    la.revenue,
    la.lineitem_count,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY la.revenue DESC) AS revenue_rank
FROM 
    CustomerOrders cs
LEFT JOIN 
    SupplierStats ss ON cs.total_orders > 0 AND ss.distinct_parts_supplied > 0
LEFT JOIN 
    LineItemAnalysis la ON cs.total_orders > 0
WHERE 
    ss.total_supply_cost IS NOT NULL
ORDER BY 
    cs.total_order_value DESC, 
    ss.total_supply_cost DESC
LIMIT 50;
