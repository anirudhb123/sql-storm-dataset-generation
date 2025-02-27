WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000.00 AND sh.level < 5
),
RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count,
           CASE 
               WHEN COUNT(o.o_orderkey) = 0 THEN 'No Orders'
               WHEN SUM(o.o_totalprice) < 500 THEN 'Low Spender'
               ELSE 'High Spender'
           END AS spending_category
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey,
           SUM(ps.ps_availqty) AS total_avail_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
)
SELECT rh.s_name, 
       rh.s_acctbal, 
       pp.p_name, 
       pp.p_retailprice,
       cs.total_spent,
       cs.spending_category,
       pi.total_avail_qty,
       pi.avg_supply_cost
FROM SupplierHierarchy rh
JOIN RankedParts pp ON pp.p_partkey IN (SELECT ps.ps_partkey FROM PartSupplierInfo ps WHERE ps.ps_suppkey = rh.s_suppkey)
LEFT JOIN CustomerStats cs ON cs.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = pp.p_partkey))
JOIN PartSupplierInfo pi ON pi.ps_partkey = pp.p_partkey
WHERE pp.rank <= 3
AND rh.s_acctbal IS NOT NULL
ORDER BY rh.s_acctbal DESC, cs.total_spent DESC
LIMIT 50;
