WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT so.o_orderkey) AS total_orders,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    SUM(CASE WHEN li.l_returnflag = 'R' THEN 1 ELSE 0 END) AS total_returns
FROM 
    orders so
JOIN 
    lineitem li ON so.o_orderkey = li.l_orderkey
JOIN 
    partsupp ps ON li.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE 
    so.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND (li.l_discount > 0.1 OR li.l_discount IS NULL)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT so.o_orderkey) > 0
ORDER BY 
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;