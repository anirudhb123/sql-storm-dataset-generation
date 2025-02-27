WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineItemDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '2023-01-01'
    GROUP BY 
        l.l_orderkey
)

SELECT 
    cs.c_custkey,
    cs.c_name,
    ss.s_suppkey,
    ss.s_name,
    ss.part_count,
    ss.total_available,
    cs.total_orders,
    cs.total_spent,
    cs.avg_order_value,
    ld.net_revenue,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        WHEN cs.total_spent > 10000 THEN 'High Roller'
        ELSE 'Casual Shopper'
    END AS customer_category,
    COALESCE(ROUND((ss.total_available / NULLIF(SUM(ss.total_available) OVER (PARTITION BY ss.s_suppkey), 0)) * 100, 2), 0) AS availability_percentage
FROM 
    CustomerOrderStats cs
FULL OUTER JOIN 
    SupplierStats ss ON cs.c_custkey IS NOT NULL OR ss.s_suppkey IS NOT NULL
LEFT JOIN 
    LineItemDetails ld ON ld.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cs.c_custkey)
WHERE 
    ss.avg_supply_cost > 20.00 OR cs.total_orders > 5
ORDER BY 
    cs.total_spent DESC NULLS LAST, 
    ss.total_available DESC;
