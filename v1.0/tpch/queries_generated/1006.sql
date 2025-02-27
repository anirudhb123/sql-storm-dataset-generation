WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
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
PartSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    ps.s_suppkey,
    ps.s_name,
    cs.c_custkey,
    cs.c_name,
    ps.total_parts,
    ps.total_available_qty,
    ps.avg_supply_cost,
    coalesce(sales.total_sales, 0) AS total_part_sales,
    coalesce(sales.total_orders, 0) AS total_part_orders,
    cs.total_orders AS customer_order_count,
    cs.total_spent,
    cs.avg_order_value
FROM SupplierStats ps
FULL OUTER JOIN CustomerOrders cs ON ps.total_parts > 5 AND cs.total_orders > 10
LEFT JOIN PartSales sales ON ps.total_parts > 3 AND sales.total_orders > 2
WHERE ps.avg_supply_cost IS NOT NULL
ORDER BY ps.s_name, cs.c_name;
