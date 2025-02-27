WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_name) DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
FilteredParts AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_brand,
        rp.name_length,
        rp.supplier_count
    FROM 
        RankedParts rp
    WHERE 
        rp.rank <= 5
),
SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_phone,
        fp.*
    FROM 
        Supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
)
SELECT 
    r.r_name AS region,
    COUNT(DISTINCT sd.s_name) AS distinct_suppliers,
    AVG(sd.name_length) AS avg_part_name_length,
    SUM(sd.supplier_count) AS total_supplier_count
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
GROUP BY 
    r.r_name
ORDER BY 
    distinct_suppliers DESC;
