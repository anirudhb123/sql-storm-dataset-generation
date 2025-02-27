WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_within_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rank_within_nation <= 5
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    pf.s_name AS supplier_name,
    pd.p_name AS part_name,
    pd.supplier_count
FROM 
    FilteredSuppliers pf
JOIN 
    partsupp ps ON pf.s_suppkey = ps.ps_suppkey
JOIN 
    part pd ON ps.ps_partkey = pd.p_partkey
WHERE 
    LENGTH(pd.p_name) > 10 AND 
    LOWER(pd.p_name) LIKE '%widget%'
ORDER BY 
    pf.s_acctbal DESC, pd.supplier_count DESC;
