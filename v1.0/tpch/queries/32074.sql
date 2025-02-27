
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = 'ManufacturerA')
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
    CASE 
        WHEN SUM(ps.ps_availqty) = 0 THEN 0 
        ELSE SUM(ps.ps_supplycost * ps.ps_availqty) / NULLIF(SUM(ps.ps_availqty), 0) 
    END AS avg_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
FROM 
    SupplierHierarchy sh
JOIN 
    supplier s ON sh.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    n.n_nationkey, n.n_name
HAVING 
    SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
ORDER BY 
    rank, total_supply_cost DESC;
