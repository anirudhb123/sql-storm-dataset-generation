WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'FRANCE')
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2022-01-01'
    GROUP BY c.c_custkey, c.c_name
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, AVG(ps.ps_supplycost) AS avg_supply_cost, COUNT(ps.ps_suppkey) AS suppliers_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderLineStats AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM lineitem l
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY l.l_orderkey
)
SELECT 
    n.n_name AS nation,
    c.c_name AS customer_name,
    COALESCE(sp.total_spent, 0) AS total_spent,
    ps.p_name AS part_name,
    ps.avg_supply_cost,
    ol.unique_parts,
    ol.net_revenue
FROM nation n
LEFT JOIN CustomerPurchases sp ON n.n_nationkey = sp.c_custkey
LEFT JOIN PartStats ps ON ps.avg_supply_cost < (SELECT AVG(p.avg_supply_cost) FROM PartStats p)
LEFT JOIN OrderLineStats ol ON ol.l_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE EXISTS (
    SELECT 1 FROM SupplierHierarchy sh WHERE sh.s_nationkey = n.n_nationkey
) 
ORDER BY total_spent DESC, avg_supply_cost ASC;
