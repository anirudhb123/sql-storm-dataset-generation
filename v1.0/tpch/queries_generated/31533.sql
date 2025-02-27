WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_mktsegment = 'BUILDING'
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
    GROUP BY p.p_partkey, p.p_name
),
DistinctNations AS (
    SELECT DISTINCT n.n_name
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 100000
)
SELECT 
    ch.c_name AS CustomerName,
    ch.o_orderkey AS OrderKey,
    ph.p_name AS PartName,
    sh.s_name AS SupplierName,
    ph.total_supply_cost AS SupplyCost,
    ROW_NUMBER() OVER (PARTITION BY ch.c_custkey ORDER BY ch.o_totalprice DESC) AS CustomerOrderRank,
    coalesce(n.r_name, 'Unknown') AS RegionName,
    CASE 
        WHEN ph.total_supply_cost < 5000 THEN 'Low Cost Supplier'
        ELSE 'High Cost Supplier'
    END AS SupplierCostCategory
FROM CustomerOrders ch
LEFT JOIN lineitem l ON ch.o_orderkey = l.l_orderkey
LEFT JOIN PartSuppliers ph ON l.l_partkey = ph.p_partkey
LEFT JOIN supplier sh ON l.l_suppkey = sh.s_suppkey
LEFT JOIN DISTINCTNations dn ON sh.s_nationkey = dn.n_nationkey
LEFT JOIN region n ON dn.n_nationkey = n.r_regionkey
WHERE ch.order_rank = 1
ORDER BY ch.c_name, ph.total_supply_cost DESC;
