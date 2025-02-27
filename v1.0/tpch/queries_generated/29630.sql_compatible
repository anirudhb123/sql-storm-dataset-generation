
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_name LIKE '%steel%'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_comment LIKE '%reliable%'
),
FinalResults AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_mfgr,
        sd.s_name,
        sd.s_address,
        rd.r_name AS region_name
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN 
        nation n ON sd.s_nationkey = n.n_nationkey
    JOIN 
        region rd ON n.n_regionkey = rd.r_regionkey
    WHERE 
        rp.rank <= 5
)
SELECT 
    p.p_partkey,
    p.p_name,
    COUNT(*) AS supplier_count,
    SUM(s.s_acctbal) AS total_acctbal,
    STRING_AGG(s.s_comment, '; ') AS joined_comments
FROM 
    FinalResults p
JOIN 
    SupplierDetails s ON p.s_name = s.s_name
GROUP BY 
    p.p_partkey, p.p_name
ORDER BY 
    supplier_count DESC, total_acctbal DESC;
