WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
PartSupplierStats AS (
    SELECT ps.ps_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT ps.ps_suppkey) AS num_suppliers,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, p.p_name
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS num_orders,
           MAX(o.o_orderdate) AS last_order_date
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
RegionWiseSupplier AS (
    SELECT n.n_regionkey, r.r_name, SUM(s.s_acctbal) AS total_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_regionkey, r.r_name
)

SELECT r.r_name, ps.p_name, pss.total_cost, cs.total_spent,
       DENSE_RANK() OVER (PARTITION BY r.r_name ORDER BY pss.total_cost DESC) AS cost_rank,
       COALESCE(cs.num_orders, 0) AS total_orders,
       CASE 
           WHEN cs.total_spent IS NULL THEN 'No Orders'
           ELSE 'Orders Placed'
       END AS order_status
FROM PartSupplierStats pss
JOIN RegionWiseSupplier rws ON rws.total_acctbal > 50000
JOIN region r ON r.r_name = rws.r_name
LEFT JOIN CustomerOrderSummary cs ON cs.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderSummary)
WHERE pss.num_suppliers > 5
ORDER BY r.r_name, pss.total_cost DESC;
