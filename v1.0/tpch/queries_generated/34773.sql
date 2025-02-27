WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_nationkey
),
PartSuppliers AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
TotalIncome AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_nationkey
),
RankedSuppliers AS (
    SELECT sh.s_suppkey, sh.s_name, RANK() OVER (ORDER BY sh.s_acctbal DESC) AS rank
    FROM SupplierHierarchy sh
)
SELECT DISTINCT 
    r.r_name, 
    n.n_name, 
    COUNT(DISTINCT ps.ps_partkey) AS count_parts,
    SUM(ts.total_sales) AS total_income,
    MAX(rk.rank) AS max_supplier_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN PartSuppliers ps ON ps.p_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
LEFT JOIN TotalIncome ts ON ts.c_nationkey = n.n_nationkey
LEFT JOIN RankedSuppliers rk ON rk.s_nationkey = n.n_nationkey
WHERE ps.ps_availqty IS NOT NULL
  AND ts.total_sales IS NOT NULL
GROUP BY r.r_name, n.n_name
HAVING SUM(ts.total_sales) > 50000
ORDER BY total_income DESC, count_parts DESC;
