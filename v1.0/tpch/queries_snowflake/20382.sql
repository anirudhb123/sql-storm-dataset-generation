
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
PartSupply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           SUM(ps.ps_supplycost * CASE 
                                    WHEN ps.ps_availqty > 100 THEN 0.9 
                                    WHEN ps.ps_availqty BETWEEN 50 AND 100 THEN 1 
                                    ELSE 1.1 
                                   END) AS adjusted_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderstatus IN ('O', 'F')
),
AggregatedLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM lineitem l
    WHERE l.l_returnflag = 'N' AND l.l_shipdate > '1997-01-01'
    GROUP BY l.l_orderkey
)
SELECT r.r_name, 
       COUNT(DISTINCT SUP.s_suppkey) AS supplier_count,
       SUM(PLI.adjusted_supplycost) AS total_adjusted_cost,
       AVG(CO.o_totalprice) AS average_order_value,
       LIT.total_revenue,
       LIT.line_count
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier SUP ON n.n_nationkey = SUP.s_nationkey
LEFT JOIN PartSupply PLI ON SUP.s_suppkey = PLI.ps_suppkey
LEFT JOIN CustomerOrders CO ON SUP.s_nationkey = CO.c_custkey
LEFT JOIN AggregatedLineItems LIT ON CO.o_orderkey = LIT.l_orderkey
WHERE r.r_name NOT LIKE '%test%' 
  AND (SUP.s_acctbal IS NOT NULL AND SUP.s_acctbal > 1000)
GROUP BY r.r_name, LIT.total_revenue, LIT.line_count
HAVING COUNT(DISTINCT CO.o_orderkey) > (SELECT COUNT(DISTINCT o.o_orderkey) / 2 FROM orders o)
ORDER BY total_adjusted_cost DESC, average_order_value ASC
LIMIT 10;
