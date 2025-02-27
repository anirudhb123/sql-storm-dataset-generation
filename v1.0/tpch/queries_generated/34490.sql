WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, 1 AS level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL

    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate, oh.level + 1
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE oh.level < 3
), 
SupplierParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_availqty, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), 
CustomerRegion AS (
    SELECT c.c_custkey, n.n_nationkey, r.r_regionkey
    FROM customer c
    INNER JOIN nation n ON c.c_nationkey = n.n_nationkey
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey
), 
Summary AS (
    SELECT oh.o_orderkey, oh.o_totalprice, cr.r_regionkey, sp.avg_supplycost
    FROM OrderHierarchy oh
    LEFT JOIN CustomerRegion cr ON oh.o_custkey = cr.c_custkey
    LEFT JOIN SupplierParts sp ON oh.o_orderkey % 100 = sp.ps_partkey
)
SELECT r.r_regionkey, COUNT(DISTINCT s.s_suppkey) AS unique_suppliers, 
       SUM(CASE WHEN s.s_acctbal IS NULL THEN 0 ELSE s.s_acctbal END) AS total_account_balance,
       AVG(ss.avg_supplycost) AS avg_supply_cost
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN Summary ss ON r.r_regionkey = ss.r_regionkey
WHERE ss.avg_supplycost IS NOT NULL OR s.s_acctbal > 1000
GROUP BY r.r_regionkey
HAVING AVG(ss.avg_supplycost) > (SELECT AVG(avg_supplycost) FROM SupplierParts)
ORDER BY unique_suppliers DESC;
