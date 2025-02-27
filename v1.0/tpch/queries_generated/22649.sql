WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name, 
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    WHERE 
        rs.rn <= 5
),
PartSupplierInfo AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey AND ps.ps_suppkey = l.l_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        SUM(pi.total_revenue) AS total_part_revenue
    FROM 
        part p
    LEFT JOIN 
        PartSupplierInfo pi ON p.p_partkey = pi.ps_partkey
    WHERE 
        p.p_size IS NOT NULL AND p.p_retailprice > 0
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(pi.total_revenue) IS NULL OR SUM(pi.total_revenue) > 50000
)
SELECT 
    fp.p_partkey, 
    fp.p_name, 
    rs.s_suppkey, 
    rs.s_name, 
    rs.s_acctbal,
    fp.total_part_revenue,
    CASE 
        WHEN fp.total_part_revenue IS NULL THEN 'No Revenue'
        WHEN fp.total_part_revenue > 100000 THEN 'High Revenue'
        ELSE 'Medium Revenue'
    END AS revenue_category
FROM 
    FilteredParts fp
LEFT JOIN 
    TopSuppliers rs ON fp.total_part_revenue IS NOT NULL
ORDER BY 
    fp.p_partkey, rs.s_acctbal DESC;
