WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, s2.s_acctbal, s2.s_nationkey, sh.level + 1
    FROM supplier s2
    INNER JOIN SupplierHierarchy sh ON sh.s_nationkey = s2.s_nationkey
    WHERE sh.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
PartSupplierRanked AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
)
SELECT
    n.n_name AS nation,
    SUM(oss.total_sales) AS total_sales,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    AVG(sh.s_acctbal) AS average_account_balance,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM nation n
LEFT JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN OrderSummary oss ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = sh.s_suppkey)
LEFT JOIN PartSupplierRanked ps ON sh.s_suppkey = ps.ps_suppkey AND ps.rank = 1
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
HAVING SUM(oss.total_sales) > (SELECT AVG(total_sales) FROM OrderSummary)
ORDER BY nation;
