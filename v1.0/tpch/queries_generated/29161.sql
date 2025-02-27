WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
SupplierComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_comment,
        CASE 
            WHEN CHARINDEX('supply', s.s_comment) > 0 THEN 'Contains supply'
            ELSE 'Does not contain supply'
        END AS comment_status
    FROM 
        supplier s
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUBSTRING(c.c_address, 1, 20) AS short_address,
        LENGTH(c.c_comment) AS comment_length
    FROM 
        customer c
    WHERE 
        c.c_acctbal > 1000
)
SELECT 
    rp.p_brand,
    COUNT(DISTINCT rp.p_partkey) AS total_parts,
    AVG(rp.p_retailprice) AS avg_price,
    MAX(CASE WHEN sc.comment_status = 'Contains supply' THEN 1 ELSE 0 END) AS has_supply_comment,
    AVG(cd.comment_length) AS avg_comment_length
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierComments sc ON ps.ps_suppkey = sc.s_suppkey
JOIN 
    CustomerDetails cd ON cd.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ps.ps_partkey) 
WHERE 
    rp.rn <= 5
GROUP BY 
    rp.p_brand
ORDER BY 
    total_parts DESC;
