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
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE LOWER(p.p_name) LIKE '%widget%'
),
SupplierComments AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.nationkey,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        COALESCE(NULLIF(s.s_comment, ''), 'No Comment') AS sanitized_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerDetails AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_address,
        c.c_phone,
        c.c_mktsegment,
        CASE 
            WHEN CHAR_LENGTH(c.c_comment) > 100 THEN LEFT(c.c_comment, 100) || '...' 
            ELSE c.c_comment 
        END AS trimmed_comment
    FROM customer c
)

SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_retailprice,
    sc.s_name,
    sc.s_address,
    cd.c_name,
    cd.trimmed_comment
FROM RankedParts rp
JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN SupplierComments sc ON ps.ps_suppkey = sc.s_suppkey
JOIN orders o ON ps.ps_partkey = o.o_orderkey
JOIN CustomerDetails cd ON o.o_custkey = cd.c_custkey
WHERE rp.rn = 1
  AND rp.p_retailprice > 100
ORDER BY rp.p_size, sc.s_name;
