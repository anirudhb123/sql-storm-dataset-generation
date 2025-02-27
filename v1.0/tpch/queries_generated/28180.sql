WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        rs.s_name AS supplier_name,
        rs.s_acctbal
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 3
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_suppkey, 
        p.p_name AS part_name, 
        fp.nation
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        FilteredSuppliers fp ON ps.ps_suppkey = fp.s_suppkey
)
SELECT 
    p.part_name,
    STRING_AGG(CONCAT(fp.nation, ' (', fp.supplier_name, ')'), '; ') AS supplier_details
FROM 
    SupplierParts p
JOIN 
    FilteredSuppliers fp ON p.ps_suppkey = fp.s_supplier_name
GROUP BY 
    p.part_name
ORDER BY 
    p.part_name;
