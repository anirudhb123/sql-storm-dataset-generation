WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, CAST(s_name AS varchar(255)) AS full_path, 1 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 100)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, CONCAT(sh.full_path, ' -> ', s.s_name), sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey AND sh.s_suppkey <> s.s_suppkey
)

SELECT 
    r_name,
    COUNT(DISTINCT n.n_name) AS nation_count,
    SUM(CASE WHEN c.c_acctbal IS NOT NULL THEN c.c_acctbal ELSE 0 END) AS total_customer_acctbal,
    ARRAY_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_acctbal) ORDER BY s.s_name) AS supplier_acctbal_list,
    MAX(CASE 
        WHEN DATE_PART('month', o.o_orderdate) = 12 AND o.o_orderstatus = 'O' 
        THEN o.o_totalprice END) AS max_december_order_totalprice,
    ROW_NUMBER() OVER (PARTITION BY CONCAT_WS('-', r.r_name, n.n_nationkey) ORDER BY SUM(l.l_extendedprice) DESC) AS supplier_rank

FROM region r 
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey 
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplierHierarchy sh ON sh.level <= 2 
LEFT JOIN supplier s ON s.s_suppkey = sh.s_suppkey 

WHERE (o.o_orderdate IS NULL OR o.o_orderdate >= '2023-01-01') 
AND (
    l.l_discount BETWEEN 0.05 AND 0.20 OR 
    (l.l_tax IS NOT NULL AND l.l_tax > 0.0)
)

GROUP BY r.r_name
HAVING COUNT(c.c_custkey) > 0 
   OR SUM(CASE WHEN sh.s_acctbal IS NOT NULL THEN sh.s_acctbal ELSE 0 END) > 1000;
