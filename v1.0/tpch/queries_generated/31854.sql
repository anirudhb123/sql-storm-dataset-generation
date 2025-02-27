WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        CAST(s.s_name AS VARCHAR(100)) AS hierarchy_path
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)

    UNION ALL

    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CAST(CONCAT(sh.hierarchy_path, ' -> ', s.s_name) AS VARCHAR(100))
    FROM 
        SupplierHierarchy sh
    JOIN 
        partsupp ps ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_final_price,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(o.o_totalprice) DESC) AS rank,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END) AS max_returned_qty,
    STRING_AGG(DISTINCT sh.hierarchy_path, ' | ') AS supplier_hierarchies
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE 
    o.o_orderdate >= DATE '2023-01-01' AND 
    o.o_orderdate < DATE '2023-10-01' AND 
    (n.n_name IS NOT NULL OR n.n_comment IS NULL)
GROUP BY 
    n.n_name
HAVING 
    SUM(o.o_totalprice) > 10000.00
ORDER BY 
    total_revenue DESC
LIMIT 10;
