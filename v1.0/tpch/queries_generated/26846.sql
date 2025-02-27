WITH FilteredParts AS (
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
        LENGTH(p.p_name) AS name_length,
        LOWER(p.p_name) AS name_lowercase
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100 AND 
        p.p_size BETWEEN 5 AND 20
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
CombinedData AS (
    SELECT 
        fp.p_partkey,
        fp.p_name,
        fp.name_length,
        sp.s_name AS supplier_name,
        sp.s_address AS supplier_address,
        sp.supplier_nation,
        COUNT(l.l_orderkey) AS order_count,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        FilteredParts fp
    LEFT JOIN 
        partsupp ps ON fp.p_partkey = ps.ps_partkey
    LEFT JOIN 
        SupplierDetails sp ON ps.ps_suppkey = sp.s_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        fp.p_partkey, fp.p_name, fp.name_length, sp.s_name, sp.s_address, sp.supplier_nation
)
SELECT 
    c.p_partkey,
    c.p_name,
    c.name_length,
    c.supplier_name,
    c.supplier_address,
    c.supplier_nation,
    COALESCE(c.order_count, 0) AS order_count,
    COALESCE(c.total_extended_price, 0) AS total_extended_price,
    SUBSTRING(c.p_name, 1, 10) AS short_name,
    CONCAT('Brand: ', c.p_brand, ', Type: ', c.p_type) AS brand_and_type_info
FROM 
    CombinedData c
ORDER BY 
    c.order_count DESC, c.total_extended_price DESC;
