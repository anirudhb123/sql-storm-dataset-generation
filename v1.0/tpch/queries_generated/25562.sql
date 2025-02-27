WITH PartDetails AS (
    SELECT 
        CONCAT(p.p_name, ' ', p.p_brand) AS full_part_info,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
    WHERE p.p_size > 25
), SupplierDetails AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        TRIM(s.s_comment) AS trimmed_comment
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), JoinedData AS (
    SELECT 
        pd.full_part_info,
        pd.p_retailprice,
        sd.s_name,
        sd.s_acctbal,
        sd.trimmed_comment
    FROM PartDetails pd
    JOIN partsupp ps ON pd.full_part_info LIKE CONCAT('%', ps.ps_partkey, '%')
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s.s_suppkey
)
SELECT 
    jd.full_part_info,
    jd.p_retailprice,
    jd.s_name,
    jd.s_acctbal
FROM JoinedData jd
WHERE jd.s_acctbal < (SELECT AVG(s_acctbal) FROM SupplierDetails)
ORDER BY jd.p_retailprice DESC, jd.s_acctbal ASC
LIMIT 100;
