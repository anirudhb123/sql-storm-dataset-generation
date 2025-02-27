WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        LENGTH(s.s_name) AS name_length,
        SUBSTRING(s.s_comment, 1, 30) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000.00
),
CombinedData AS (
    SELECT 
        r.r_name AS region,
        n.n_name AS nation,
        sp.name_length,
        sp.short_comment,
        rp.p_name,
        rp.p_type,
        rp.p_retailprice
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    JOIN 
        SupplierDetails sp ON s.s_suppkey = sp.s_suppkey
)
SELECT 
    region,
    nation,
    COUNT(p_name) AS part_count,
    AVG(p_retailprice) AS avg_retail_price,
    MAX(name_length) AS max_name_length,
    STRING_AGG(short_comment, '; ') AS aggregated_comments
FROM 
    CombinedData
GROUP BY 
    region, nation
ORDER BY 
    region, nation;
