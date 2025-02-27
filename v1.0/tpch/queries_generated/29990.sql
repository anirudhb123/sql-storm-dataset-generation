WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_brand LIKE 'Brand#%'
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        REPLACE(s.s_comment, 'obsolete', 'updated') AS updated_comment
    FROM 
        supplier s
    WHERE
        s.s_acctbal > 1000.00
),
TopPartSuppliers AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) AS supplier_rank
    FROM 
        partsupp ps
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    JOIN 
        FilteredSuppliers s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        p.rn <= 5
)
SELECT 
    p.p_name,
    COUNT(*) AS supplier_count,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    SUM(ps.ps_availqty) AS total_available_quantity,
    STRING_AGG(s.s_name, ', ') AS supplier_names
FROM 
    TopPartSuppliers ps
JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_name
ORDER BY 
    supplier_count DESC, max_supply_cost DESC;
