WITH SupplierAggregate AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ROW_NUMBER() OVER (ORDER BY total_supply_value DESC) AS rank
    FROM SupplierAggregate s
    WHERE total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierAggregate)
)
SELECT c.c_custkey, c.c_name, co.total_orders, co.total_spent, ns.r_name, ts.s_name AS top_supplier
FROM CustomerOrderSummary co
JOIN nation n ON co.c_custkey = n.n_nationkey
JOIN NationRegion ns ON n.n_nationkey = ns.n_nationkey
LEFT JOIN TopSuppliers ts ON ts.rank <= 5
WHERE co.total_orders > 0
ORDER BY co.total_spent DESC, c.c_name;
