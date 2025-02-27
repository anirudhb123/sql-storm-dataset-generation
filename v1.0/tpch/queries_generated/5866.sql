WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_avail_qty, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartOrderDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_quantity) AS total_quantity_sold, 
        AVG(l.l_extendedprice) AS avg_extended_price
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    cs.c_name AS customer_name, 
    ss.s_name AS supplier_name, 
    ps.p_name AS part_name, 
    ps.total_quantity_sold, 
    ps.avg_extended_price, 
    cs.total_orders, 
    cs.total_spent, 
    ss.total_avail_qty, 
    ss.total_supply_cost
FROM 
    CustomerOrders cs
JOIN 
    SupplierStats ss ON ss.total_supply_cost > 5000
JOIN 
    PartOrderDetails ps ON ps.total_quantity_sold > 100
WHERE 
    cs.total_orders > 10
ORDER BY 
    cs.total_spent DESC, 
    ps.total_quantity_sold DESC
LIMIT 50;
