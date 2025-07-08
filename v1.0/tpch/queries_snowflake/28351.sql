
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        p.p_name,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        rnk,
        s_suppkey,
        s_name,
        s_acctbal,
        s_comment,
        p_name
    FROM 
        RankedSuppliers
    WHERE 
        rnk <= 3
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT fs.s_suppkey) AS supplier_count,
    LISTAGG(fs.s_name, ', ') AS top_suppliers,
    SUM(fs.s_acctbal) AS total_acctbal,
    AVG(fs.s_acctbal) AS avg_acctbal
FROM 
    FilteredSuppliers fs
JOIN 
    supplier s ON fs.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_acctbal DESC;
