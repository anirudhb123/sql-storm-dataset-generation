
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_container,
        r.r_name AS region_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        p.p_type ILIKE '%special%'
    AND 
        p.p_comment ILIKE '%high%quality%'
),
TopBrandSuppliers AS (
    SELECT 
        region_name,
        COUNT(*) AS supplier_count,
        LISTAGG(CONCAT('Brand: ', p_brand, ' Supplier: ', supplier_name), '; ') WITHIN GROUP (ORDER BY p_brand) AS brand_supplier_details
    FROM 
        RankedParts
    WHERE 
        rank <= 5
    GROUP BY 
        region_name, p_brand, supplier_name
)
SELECT 
    region_name,
    supplier_count,
    brand_supplier_details
FROM 
    TopBrandSuppliers
ORDER BY 
    supplier_count DESC;
