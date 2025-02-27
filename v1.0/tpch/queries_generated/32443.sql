WITH RECURSIVE SupplierTree AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, st.level + 1
    FROM supplier s
    JOIN SupplierTree st ON s.s_suppkey = st.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
PartStats AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_supply_cost, COUNT(*) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
RankedParts AS (
    SELECT p.p_name, ps.avg_supply_cost, ps.supplier_count,
           RANK() OVER (ORDER BY ps.avg_supply_cost DESC) AS rank
    FROM part p
    JOIN PartStats ps ON p.p_partkey = ps.p_partkey
    WHERE ps.avg_supply_cost IS NOT NULL
)
SELECT
    rt.s_name AS supplier_name,
    co.total_orders,
    rp.p_name AS part_name,
    rp.avg_supply_cost,
    rp.supplier_count,
    st.level
FROM RankedParts rp
JOIN CustomerOrders co ON co.total_orders > (
    SELECT AVG(total_orders) FROM CustomerOrders
)
JOIN SupplierTree st ON st.s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
LEFT JOIN supplier rt ON rt.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = rp.p_partkey
    ORDER BY ps.ps_supplycost ASC
    LIMIT 1
)
WHERE rp.rank <= 10
ORDER BY rp.avg_supply_cost DESC, co.total_orders DESC;
