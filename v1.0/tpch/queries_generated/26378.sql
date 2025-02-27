WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        LENGTH(s.s_comment) AS comment_length,
        TRIM(UPPER(REPLACE(s.s_comment, ' ', ''))) AS normalized_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length,
        REGEXP_REPLACE(LOWER(p.p_comment), '[^a-z0-9]', '') AS cleaned_comment
    FROM 
        part p
),
CombinedInfo AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        pi.p_partkey,
        pi.p_name,
        pi.p_retailprice,
        si.nation_name,
        si.region_name,
        si.acctbal,
        si.comment_length AS supplier_comment_length,
        pi.comment_length AS part_comment_length,
        CONCAT(si.normalized_comment, ' ', pi.cleaned_comment) AS combined_comment
    FROM 
        SupplierInfo si
    CROSS JOIN 
        PartInfo pi
)
SELECT 
    nation_name,
    COUNT(DISTINCT s_suppkey) AS distinct_suppliers,
    COUNT(DISTINCT p_partkey) AS distinct_parts,
    AVG(acctbal) AS avg_account_balance,
    MAX(part_comment_length) AS max_part_comment_length,
    AVG(supplier_comment_length) AS avg_supplier_comment_length
FROM 
    CombinedInfo
GROUP BY 
    nation_name
ORDER BY 
    nation_name;
