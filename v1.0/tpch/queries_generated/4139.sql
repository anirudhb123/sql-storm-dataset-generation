WITH SupplierAggregates AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
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
        COUNT(o.o_orderkey) AS orders_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    n.n_name,
    SUM(SA.total_supply_cost) AS region_supply_cost,
    COUNT(DISTINCT HVC.c_custkey) AS high_value_customers,
    AVG(HVC.total_spent) AS avg_spending_high_value_customers,
    COUNT(DISTINCT l.l_orderkey) AS total_orders
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierAggregates SA ON s.s_suppkey = SA.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    HighValueCustomers HVC ON HVC.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        WHERE l.l_orderkey = o.o_orderkey
    )
GROUP BY 
    n.n_name
ORDER BY 
    region_supply_cost DESC
WITH ROLLUP;
