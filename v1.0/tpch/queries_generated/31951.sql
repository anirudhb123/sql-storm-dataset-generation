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
        SupplierHierarchy sh ON ps.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_mfgr = sh.s_name)
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)

SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_sales,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    MAX(l.l_returnflag) AS max_return_flag,
    STRING_AGG(DISTINCT pt.p_type, ', ') AS product_types,
    MAX(CASE WHEN sh.level IS NULL THEN 'No Supplier' ELSE 'Supplier Exists' END) AS supplier_status
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
LEFT JOIN 
    part pt ON l.l_partkey = pt.p_partkey
WHERE 
    o.o_orderdate > '2023-01-01'
    AND (l.l_discount IS NULL OR l.l_discount < 0.1)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    total_sales DESC;
