WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS comment_length,
        REGEXP_REPLACE(LOWER(s.s_comment), '[^a-z]', '') AS verbose_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z]', '') AS verbose_comment
    FROM 
        part p
),
CombinedDetails AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        pd.p_partkey,
        pd.p_name,
        sd.nation_name,
        sd.comment_length AS supplier_comment_length,
        pd.comment_length AS part_comment_length,
        CONCAT(sd.verbose_comment, ' ', pd.verbose_comment) AS combined_comment
    FROM 
        SupplierDetails sd
    CROSS JOIN 
        PartDetails pd
)
SELECT 
    s_suppkey,
    s_name,
    p_partkey,
    p_name,
    LENGTH(combined_comment) AS total_comment_length,
    (SELECT COUNT(*) FROM orders o WHERE o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = CombinedDetails.nation_name))) AS total_orders
FROM 
    CombinedDetails
ORDER BY 
    total_comment_length DESC, total_orders DESC
LIMIT 10;
