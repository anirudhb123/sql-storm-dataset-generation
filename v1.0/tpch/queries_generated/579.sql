WITH SupplierAnalysis AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    cs.c_name AS customer_name,
    cs.total_orders,
    cs.total_spent,
    sa.s_name AS supplier_name,
    sa.total_available_quantity,
    sa.avg_supply_cost,
    ls.revenue AS order_revenue,
    ls.avg_quantity AS average_quantity,
    ROW_NUMBER() OVER (PARTITION BY cs.c_custkey ORDER BY cs.total_spent DESC) AS customer_rank,
    CASE
        WHEN cs.total_orders > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS customer_type
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    SupplierAnalysis sa ON cs.total_orders > 0
LEFT JOIN 
    LineItemStats ls ON ls.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    cs.last_order_date >= DATEADD(month, -12, CURRENT_DATE)
ORDER BY 
    cs.total_spent DESC, cs.c_name;
