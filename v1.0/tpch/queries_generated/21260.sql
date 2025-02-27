WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < (SELECT MIN(s_acctbal) FROM supplier WHERE s_nationkey <> sh.s_nationkey)
)

SELECT 
    p.p_partkey,
    p.p_name,
    SUM(COALESCE(l.l_extendedprice * (1 - l.l_discount), 0)) AS total_revenue,
    AVG(s.s_acctbal) OVER (PARTITION BY p.p_partkey) AS avg_account_balance,
    CASE 
        WHEN SUM(l.l_quantity) IS NULL THEN 'No Sales'
        WHEN SUM(l.l_quantity) = 0 THEN 'Out of Stock'
        ELSE 'Available'
    END AS stock_status,
    CUBE (
        CASE WHEN n.n_name IS NULL THEN 'Unknown Nation' ELSE n.n_name END,
        p.p_brand
    ) AS sales_by_brand_and_nation
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    partsupp ps ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100
    AND EXISTS (SELECT 1 FROM customer c WHERE c.c_nationkey = n.n_nationkey)
    AND s.s_suppkey IN (SELECT sh.s_suppkey FROM SupplierHierarchy sh)
GROUP BY 
    p.p_partkey, p.p_name, n.n_name, p.p_brand
HAVING 
    SUM(COALESCE(l.l_quantity, 0)) > 0 OR NULLIF(COUNT(*), 0) IS NULL
ORDER BY 
    total_revenue DESC, avg_account_balance NULLS LAST
FETCH FIRST 10 ROWS ONLY;
