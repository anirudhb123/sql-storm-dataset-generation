WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_suppkey = 1 -- start from a specific supplier key
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierAggregates AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           COUNT(*) AS item_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
    GROUP BY l.l_orderkey
)
SELECT p.p_partkey, 
       p.p_name, 
       ph.s_acctbal AS supplier_balance, 
       cu.total_spent AS customer_spending,
       li.revenue AS order_revenue,
       CASE 
           WHEN ph.level IS NULL THEN 'Base Supplier'
           ELSE 'Sub Supplier Level ' || ph.level
       END AS supplier_level,
       COALESCE(pr.avg_cost, 0) AS average_supply_cost
FROM part p
LEFT JOIN PartSupplierAggregates pr ON p.p_partkey = pr.ps_partkey
LEFT JOIN SupplierHierarchy ph ON ph.s_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ph.s_nationkey)
LEFT JOIN CustomerOrders cu ON cu.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderstatus = 'F'))
LEFT JOIN AggregatedLineItems li ON li.l_orderkey = (SELECT MAX(l2.l_orderkey) FROM lineitem l2 WHERE l2.l_partkey = p.p_partkey)
WHERE p.p_size BETWEEN 1 AND 25
  AND (p.p_retailprice > 100.00 OR p.p_comment LIKE '%fragile%')
ORDER BY supplier_balance DESC, order_revenue DESC;
