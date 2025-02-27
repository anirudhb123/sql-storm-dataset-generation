WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        ranked.s_name,
        ranked.total_supply_cost
    FROM RankedSuppliers ranked
    JOIN nation n ON ranked.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE ranked.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cus.c_name AS customer_name,
    cus.total_spent,
    suppliers.region_name,
    suppliers.nation_name,
    suppliers.s_name AS supplier_name,
    suppliers.total_supply_cost
FROM CustomerOrders cus
JOIN HighCostSuppliers suppliers ON cus.total_spent > 5000
ORDER BY cus.total_spent DESC, suppliers.total_supply_cost DESC;
