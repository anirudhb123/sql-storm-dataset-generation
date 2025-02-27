WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON co.o_orderkey = o.o_orderkey
    WHERE o.o_orderdate < '2023-01-01'
),
OrderSummary AS (
    SELECT co.c_custkey, co.c_name, COUNT(co.o_orderkey) AS total_orders, SUM(co.o_totalprice) AS total_spent
    FROM CustomerOrders co
    WHERE co.o_orderstatus = 'O'
    GROUP BY co.c_custkey, co.c_name
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
SupplierRegion AS (
    SELECT s.s_suppkey, s.s_name, rg.r_name, s.s_acctbal
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN region rg ON n.n_regionkey = rg.r_regionkey
    WHERE s.s_acctbal IS NOT NULL
)
SELECT os.c_name, os.total_orders, os.total_spent, COALESCE(ps.total_available, 0) AS total_avail_qty, COALESCE(ps.avg_supply_cost, 0) AS avg_supply_cost, sr.r_name AS supplier_region
FROM OrderSummary os
LEFT JOIN PartSupplierInfo ps ON os.total_orders > ps.total_available
LEFT JOIN SupplierRegion sr ON ps.ps_partkey = sr.s_suppkey
WHERE os.total_spent > 1000
ORDER BY os.total_spent DESC, os.c_name ASC
LIMIT 10;
