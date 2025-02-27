WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        substr(s.s_address, 1, 15) AS short_address,
        n.n_name AS nation,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.short_address,
        s.nation,
        s.s_acctbal
    FROM 
        RankedSuppliers s
    WHERE 
        s.rank <= 3
),
SupplierParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_size,
        p.p_retailprice,
        ps.ps_availqty,
        tp.s_name AS supplier_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers tp ON ps.ps_suppkey = tp.s_suppkey
    WHERE 
        p.p_size BETWEEN 1 AND 10
)
SELECT 
    sp.supplier_name,
    COUNT(sp.p_partkey) AS total_parts,
    SUM(sp.p_retailprice * sp.ps_availqty) AS total_value,
    GROUP_CONCAT(DISTINCT sp.p_name ORDER BY sp.p_name ASC) AS part_names
FROM 
    SupplierParts sp
GROUP BY 
    sp.supplier_name
ORDER BY 
    total_value DESC;
