WITH PartCounts AS (
    SELECT 
        p_partkey,
        LENGTH(p_name) AS name_length,
        p_mfgr,
        COUNT(*) OVER (PARTITION BY p_mfgr) AS mfgr_count
    FROM part
),
NationCounts AS (
    SELECT 
        n_nationkey,
        n_name,
        LENGTH(n_comment) AS comment_length,
        COUNT(*) OVER (PARTITION BY n_regionkey) AS region_count
    FROM nation
),
SupplierInfo AS (
    SELECT 
        s_suppkey,
        s_name,
        SPLIT_PART(s_address, ' ', 1) AS address_first_word,
        LENGTH(s_comment) AS comment_length
    FROM supplier
    WHERE s_acctbal > 1000
),
CombinedData AS (
    SELECT 
        pc.p_partkey,
        pc.name_length,
        nc.n_name AS nation_name,
        nc.comment_length AS nation_comment_length,
        si.address_first_word,
        si.comment_length AS supplier_comment_length,
        pc.mfgr_count,
        nc.region_count
    FROM PartCounts pc
    JOIN NationCounts nc ON pc.p_partkey % 10 = nc.n_nationkey % 10
    JOIN SupplierInfo si ON pc.p_partkey % 5 = si.s_suppkey % 5
)
SELECT 
    CONCAT(CAST(p_partkey AS VARCHAR), ' - ', nation_name) AS part_nation_info,
    name_length,
    mfgr_count,
    region_count,
    address_first_word,
    supplier_comment_length
FROM CombinedData
ORDER BY name_length DESC, mfgr_count ASC;
