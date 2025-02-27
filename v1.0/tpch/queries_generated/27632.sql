WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000  -- Initial filter for high account balance
    
    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5  -- Limit recursion to a max of 5 levels deep
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    SUM(sh.s_acctbal) AS total_account_balance,
    AVG(sh.s_acctbal) AS avg_account_balance,
    STRING_AGG(DISTINCT sh.s_name, ', ') AS supplier_names
FROM 
    SupplierHierarchy sh
JOIN 
    nation n ON sh.s_nationkey = n.n_nationkey
GROUP BY 
    n.n_name
ORDER BY 
    total_suppliers DESC, avg_account_balance DESC;
