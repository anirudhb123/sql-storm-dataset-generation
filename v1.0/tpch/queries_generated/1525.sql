WITH CustomerOrders AS (
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
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
)

SELECT 
    co.c_name AS customer_name,
    co.total_orders,
    co.total_spent,
    sp.s_name AS supplier_name,
    sp.total_available,
    sp.avg_supply_cost,
    COUNT(DISTINCT ro.o_orderkey) AS top_orders_count
FROM 
    CustomerOrders co
LEFT JOIN 
    SupplierParts sp ON sp.total_available > 1000
JOIN 
    RankedOrders ro ON co.c_custkey = ro.o_custkey AND ro.order_rank <= 5
WHERE 
    co.total_spent > 10000
GROUP BY 
    co.c_name, co.total_orders, co.total_spent, sp.s_name, sp.total_available, sp.avg_supply_cost
ORDER BY 
    co.total_spent DESC, co.total_orders DESC;
