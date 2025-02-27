WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey AND s.s_suppkey <> sh.s_suppkey
    WHERE sh.level < 5
),
FilteredPart AS (
    SELECT p.p_partkey, COUNT(ps.ps_suppkey) AS supplier_count, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING AVG(ps.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
CustomerOrder AS (
    SELECT DISTINCT c.c_custkey, c.c_mktsegment, o.o_orderkey, o.o_orderstatus
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment IN ('BUILDING', 'FURNITURE')
    AND o.o_orderstatus = 'O'
),
RankedOrders AS (
    SELECT o.o_orderkey, DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
),
NationSupplier AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS num_suppliers
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 5
)

SELECT 
    n.n_name AS Nation,
    SUM(co.o_orderkey IS NOT NULL) AS TotalCustomerOrders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS TotalReturns,
    MAX(fp.supplier_count) AS MaxSupplierCount,
    AVG(r.price_rank) AS AvgOrderPriceRank
FROM NationSupplier n
LEFT JOIN CustomerOrder co ON n.n_name = (SELECT n_name FROM nation WHERE n_nationkey = co.c_custkey) -- Bizarre subquery referencing itself
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN FilteredPart fp ON fp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost IN (SELECT AVG(ps_supplycost) FROM partsupp))
LEFT JOIN RankedOrders r ON r.o_orderkey = co.o_orderkey
WHERE n.num_suppliers IS NOT NULL
GROUP BY n.n_name
HAVING COUNT(co.o_orderkey) > 10 OR MAX(fp.supplier_count) IS NULL
ORDER BY 2 DESC, 3 ASC;
