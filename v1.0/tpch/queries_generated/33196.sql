WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS VARCHAR(100)) AS full_name_path
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CAST(CONCAT(sh.full_name_path, ' -> ', s.s_name) AS VARCHAR(100))
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.s_suppkey != s.s_suppkey
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS average_account_balance,
    MAX(p.p_retailprice) AS max_part_retail_price,
    MIN(p.p_retailprice) AS min_part_retail_price,
    STRING_AGG(DISTINCT sh.full_name_path, ', ') AS supplier_hierarchy
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 0 
ORDER BY 
    total_revenue DESC;
