WITH CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopProducts AS (
    SELECT 
        p.p_partkey, 
        p.p_name,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    ORDER BY 
        total_quantity DESC
    LIMIT 10
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    co.c_name,
    COALESCE(co.order_count, 0) AS total_orders,
    COALESCE(co.total_spent, 0.00) AS total_spent,
    tp.p_name AS top_product,
    ss.s_name AS supplier_name,
    ss.avg_supply_cost,
    ss.part_count
FROM 
    CustomerOrders co
LEFT JOIN 
    TopProducts tp ON tp.total_quantity = (
        SELECT MAX(total_quantity) FROM TopProducts
    )
LEFT JOIN 
    SupplierStats ss ON ss.part_count > 0
WHERE 
    co.total_spent IS NOT NULL 
    AND (ss.avg_supply_cost IS NOT NULL OR ss.part_count IS NOT NULL)
ORDER BY 
    co.total_spent DESC, ss.avg_supply_cost ASC;
