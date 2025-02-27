WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
), RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size >= 10
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
), CustomerPreferential AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, SUM(hv.order_value) AS total_order_value
    FROM customer c
    LEFT JOIN HighValueOrders hv ON c.c_custkey = hv.o_orderkey
    GROUP BY c.c_custkey, c.c_name, c.c_mktsegment
    HAVING SUM(hv.order_value) IS NOT NULL
), FinalReport AS (
    SELECT DISTINCT r.r_name, SUM(cp.total_order_value) AS regional_order_value
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customerpreferential cp ON cp.c_mktsegment = n.n_name
    GROUP BY r.r_name
), SupplierSummary AS (
    SELECT sh.s_suppliername, SUM(sh.s_acctbal) AS total_balance, COUNT(DISTINCT cp.c_custkey) AS total_customers
    FROM SupplierHierarchy sh
    JOIN customerpreferential cp ON sh.s_nationkey = cp.c_custkey
    GROUP BY sh.s_suppliername
)
SELECT fs.r_name, fs.regional_order_value, ss.total_balance, ss.total_customers
FROM FinalReport fs
FULL OUTER JOIN SupplierSummary ss ON fs.r_name = ss.s_suppliername
WHERE fs.regional_order_value IS NOT NULL OR ss.total_balance IS NOT NULL
ORDER BY fs.regional_order_value DESC NULLS LAST, ss.total_balance DESC NULLS LAST;
