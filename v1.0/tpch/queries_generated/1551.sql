WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        COUNT(*) AS total_items
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)

SELECT 
    cs.c_name,
    cs.total_orders,
    cs.total_spent,
    ss.s_name,
    ss.part_count,
    ss.total_cost,
    ld.total_revenue,
    ld.total_items
FROM 
    CustomerOrderSummary cs
LEFT JOIN 
    SupplierSummary ss ON ss.total_cost = (
        SELECT 
            MAX(total_cost) 
        FROM 
            SupplierSummary
        WHERE 
            total_cost < cs.total_spent
    )
LEFT JOIN 
    LineItemDetails ld ON cs.total_orders = ld.total_items
WHERE 
    cs.total_orders > 0 
    AND ss.total_cost IS NOT NULL
ORDER BY 
    cs.total_spent DESC, ss.total_cost ASC
LIMIT 10;
