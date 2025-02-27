WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, COUNT(DISTINCT ps.ps_suppkey) AS available_suppliers,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT si.s_name, si.nation_name, ps.p_name, ps.available_suppliers, ps.avg_supply_cost,
       co.c_name, co.order_count, co.total_spent
FROM SupplierInfo si
JOIN PartStats ps ON ps.available_suppliers > 0
LEFT JOIN CustomerOrders co ON co.order_count > 0
WHERE si.s_acctbal IS NOT NULL
  AND (si.s_acctbal > 1000 OR ps.avg_supply_cost < (SELECT AVG(ps_supplycost) FROM partsupp))
ORDER BY co.total_spent DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;
