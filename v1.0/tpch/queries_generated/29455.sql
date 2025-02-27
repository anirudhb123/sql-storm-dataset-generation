WITH EnhancedPartData AS (
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
        CONCAT(p.p_name, ' - ', p.p_brand) AS full_description
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
        AND LENGTH(p.p_comment) > 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        LENGTH(s.s_comment) AS comment_length,
        s.n_nationkey,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE 'N%'
),
CombinedData AS (
    SELECT 
        epd.p_partkey,
        epd.full_description,
        sd.s_name AS supplier_name,
        sd.region_name,
        sd.comment_length
    FROM 
        EnhancedPartData epd
    LEFT JOIN 
        SupplierDetails sd ON epd.p_partkey % 10 = sd.s_suppkey % 10
)
SELECT 
    c.c_custkey,
    c.c_name,
    c.c_address,
    cd.full_description,
    cd.supplier_name,
    cd.region_name
FROM 
    customer c
LEFT JOIN 
    CombinedData cd ON c.c_custkey % 10 = cd.p_partkey % 10
WHERE 
    c.c_acctbal > 1000
ORDER BY 
    c.c_name, cd.region_name;
