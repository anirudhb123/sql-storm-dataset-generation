WITH RankedParts AS (
    SELECT 
        p_name,
        p_mfgr,
        p_type,
        p_brand,
        p_container,
        p_comment,
        ROW_NUMBER() OVER (PARTITION BY p_type ORDER BY p_retailprice DESC) AS rank
    FROM part
    WHERE p_size > 10
),
SupplierComments AS (
    SELECT
        s_name,
        s_comment,
        LENGTH(s_comment) AS comment_length,
        REGEXP_REPLACE(s_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment
    FROM supplier
    WHERE s_acctbal > 1000
),
TopParts AS (
    SELECT 
        rp.p_name,
        rp.p_mfgr,
        rp.p_type,
        sc.s_name,
        sc.comment_length,
        sc.cleaned_comment
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN supplier sc ON ps.ps_suppkey = sc.s_suppkey
    WHERE rp.rank <= 5
)
SELECT
    tp.p_name,
    tp.p_mfgr,
    tp.p_type,
    tp.s_name,
    tp.comment_length,
    CHAR_LENGTH(tp.cleaned_comment) AS clean_comment_length,
    SUBSTRING(tp.cleaned_comment, 1, 50) AS short_comment
FROM TopParts tp
ORDER BY tp.p_type, tp.comment_length DESC;
