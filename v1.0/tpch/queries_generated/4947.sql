WITH PartSupplierStats AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegionStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_name
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_available_quantity,
    ps.avg_supply_cost,
    co.total_orders,
    co.total_spent,
    co.avg_order_value,
    nr.region_name,
    nr.total_suppliers
FROM PartSupplierStats ps
JOIN CustomerOrderStats co ON co.total_orders > 0 
LEFT JOIN NationRegionStats nr ON nr.total_suppliers > 5 
WHERE ps.total_available_quantity > 100
  AND (ps.avg_supply_cost IS NOT NULL OR co.total_spent IS NULL)
ORDER BY ps.p_partkey, co.total_spent DESC
LIMIT 50;
