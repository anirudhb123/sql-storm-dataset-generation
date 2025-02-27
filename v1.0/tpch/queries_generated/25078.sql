WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name AS region,
        COUNT(DISTINCT ps.ps_partkey) AS distinct_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, r.r_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ss.s_name,
    ss.region,
    ss.distinct_parts,
    ss.total_supply_value,
    ss.avg_supply_cost,
    cos.c_name,
    cos.total_orders,
    cos.total_spent,
    cos.avg_order_value
FROM SupplierStats ss
JOIN CustomerOrderStats cos ON ss.distinct_parts > cos.total_orders
WHERE ss.total_supply_value > 50000
ORDER BY ss.total_supply_value DESC, cos.total_spent DESC
LIMIT 10;
