
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 100000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, p.p_size,
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice IS NOT NULL
),
AvgSupplyCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING AVG(ps.ps_supplycost) > 50.00
)
SELECT 
    c.c_custkey,
    c.c_name,
    n.n_name AS nation,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_filled_order,
    MAX(COALESCE(sh.level, 0)) AS supplier_level,
    LISTAGG(DISTINCT p.p_name, ', ') WITHIN GROUP (ORDER BY p.p_name) AS part_names
FROM customer c
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN FilteredParts p ON l.l_partkey = p.p_partkey
LEFT JOIN AvgSupplyCost ac ON p.p_partkey = ac.ps_partkey
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.n_nationkey
WHERE c.c_acctbal IS NOT NULL AND (o.o_orderdate > DATEADD(year, -1, '1998-10-01') OR o.o_orderstatus IS NULL)
GROUP BY c.c_custkey, c.c_name, n.n_name
HAVING SUM(COALESCE(l.l_extendedprice, 0)) > 10000.00
ORDER BY total_filled_order DESC, c.c_name ASC;
