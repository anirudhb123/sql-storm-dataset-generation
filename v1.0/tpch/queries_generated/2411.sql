WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
), 
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        order_value > 10000
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    sp.total_avail_qty,
    sp.avg_supply_cost,
    hvo.order_value
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierParts sp ON co.c_custkey = sp.s_suppkey  -- Kinship for the sake of example
LEFT JOIN 
    HighValueOrders hvo ON co.total_orders > 5 AND hvo.order_value > 10000
WHERE 
    (co.total_spent IS NOT NULL OR sp.avg_supply_cost IS NOT NULL)
ORDER BY 
    co.total_spent DESC, co.total_orders ASC
LIMIT 50;
