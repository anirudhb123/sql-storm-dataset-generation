WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(ps.ps_supplycost) AS avg_supply_cost
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
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
LineitemRanked AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        l.l_quantity,
        RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_discount DESC) AS discount_rank
    FROM 
        lineitem l
)
SELECT 
    ns.n_name,
    COUNT(DISTINCT co.c_custkey) AS customer_count,
    COALESCE(SUM(ss.total_supply_cost), 0) AS total_supply_cost,
    COALESCE(SUM(co.total_spent), 0) AS total_spent,
    AVG(CASE WHEN co.total_orders IS NOT NULL THEN co.total_orders ELSE 0 END) AS avg_orders_per_customer,
    MAX(ps.p_retailprice) AS highest_price_part
FROM 
    nation ns
LEFT JOIN 
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey IN (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = ns.n_nationkey
    )
LEFT JOIN 
    partsupp ps ON ps.ps_suppkey = s.s_suppkey
WHERE 
    ns.n_name IS NOT NULL
GROUP BY 
    ns.n_name
HAVING 
    COUNT(DISTINCT co.c_custkey) > 10 OR SUM(ss.total_supply_cost) > 10000
ORDER BY 
    customer_count DESC, total_supply_cost DESC;
