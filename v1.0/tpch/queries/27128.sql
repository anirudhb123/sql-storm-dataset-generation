
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        COUNT(ps.ps_partkey) AS supplier_count,
        STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers,
        STRING_AGG(DISTINCT s.s_address, '; ') AS supplier_addresses
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        rp.p_name,
        rp.supplier_count,
        rp.suppliers,
        rp.supplier_addresses
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rp.supplier_count > 5
)
SELECT 
    region_name,
    nation_name,
    p_name,
    supplier_count,
    suppliers,
    supplier_addresses
FROM 
    TopSuppliers
ORDER BY 
    region_name, nation_name, supplier_count DESC;
