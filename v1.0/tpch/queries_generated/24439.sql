WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
    UNION ALL
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
)
SELECT
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN o.o_totalprice IS NOT NULL THEN o.o_totalprice ELSE 0 END) AS total_sales,
    MAX(p.p_retailprice) FILTER (WHERE p.p_size IS NOT NULL AND p.p_retailprice < (SELECT MAX(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)) AS max_retail_price,
    STRING_AGG(DISTINCT p.p_name) AS part_names,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY total_sales DESC) AS sales_rank
FROM
    nation n
LEFT JOIN
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN
    part p ON l.l_partkey = p.p_partkey
LEFT JOIN
    SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
WHERE
    (c.c_acctbal IS NOT NULL AND c.c_acctbal > 0) OR (l.l_discount IS NOT NULL AND l.l_discount > 0.1)
GROUP BY
    n.n_name
HAVING
    COUNT(DISTINCT c.c_custkey) > 0
ORDER BY
    total_sales DESC NULLS LAST;
