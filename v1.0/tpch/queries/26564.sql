WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
Summary AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        s.s_name AS supplier_name,
        s.total_available_quantity,
        s.average_supply_cost,
        c.c_name AS customer_name,
        c.total_orders,
        c.total_spent,
        STRING_AGG(DISTINCT s.part_names, '; ') AS all_part_names
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
    JOIN CustomerOrders c ON c.c_custkey = s.s_nationkey 
    GROUP BY r.r_name, n.n_name, s.s_name, s.total_available_quantity, s.average_supply_cost, c.c_name, c.total_orders, c.total_spent
)
SELECT 
    region_name,
    nation_name,
    supplier_name,
    total_available_quantity,
    average_supply_cost,
    customer_name,
    total_orders,
    total_spent,
    all_part_names
FROM Summary
WHERE total_spent > 1000
ORDER BY total_spent DESC, total_orders DESC;