WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CAST(s.s_name AS varchar(100)) AS hierarchy_path
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_acctbal,
        CONCAT(SH.hierarchy_path, ' -> ', s.s_name)
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        SupplierHierarchy SH ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_retailprice > 50)
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(o.o_totalprice) AS total_sales,
    AVG(l.l_quantity) AS avg_line_quantity,
    MAX(l.l_extendedprice) AS max_extended_price,
    CASE 
        WHEN SUM(o.o_totalprice) IS NULL THEN 'No Sales'
        ELSE 'Sales Present'
    END AS sales_status,
    s.s_name,
    s.s_acctbal,
    SH.hierarchy_path
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    SupplierHierarchy SH ON SH.s_suppkey = o.o_orderkey % 10
LEFT JOIN 
    supplier s ON s.s_suppkey = l.l_suppkey
WHERE 
    l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    n.n_name, s.s_name, s.s_acctbal, SH.hierarchy_path
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_sales DESC, avg_line_quantity ASC;
