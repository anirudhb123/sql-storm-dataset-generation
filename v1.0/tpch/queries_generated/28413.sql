WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank <= 3
),
SupplierSummary AS (
    SELECT 
        COUNT(*) AS supplier_count,
        AVG(s_acctbal) AS avg_acctbal
    FROM 
        FilteredSuppliers
)
SELECT 
    p.p_name,
    fs.s_name,
    fs.s_acctbal,
    ss.supplier_count,
    ss.avg_acctbal
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    FilteredSuppliers fs ON ps.ps_suppkey = fs.s_suppkey,
    SupplierSummary ss
WHERE 
    p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY 
    p.p_name, fs.s_acctbal DESC;
