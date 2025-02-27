WITH PartDetails AS (
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
        CONCAT(REPLACE(p.p_name, ' ', '_'), '_', p.p_brand) AS processed_name
    FROM part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment,
        CONCAT(s.s_name, ' - ', s.s_address) AS supplier_details
    FROM supplier s
),
NationDetails AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        n.n_comment,
        REGEXP_REPLACE(n.n_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment
    FROM nation n
), 
StringBenchmark AS (
    SELECT 
        pd.processed_name || ' (' || si.supplier_details || ')' AS benchmark_string,
        nd.sanitized_comment 
    FROM PartDetails pd
    JOIN SupplierInfo si ON pd.p_partkey % 10 = si.s_suppkey % 10
    JOIN NationDetails nd ON si.s_nationkey = nd.n_nationkey
)
SELECT 
    benchmark_string,
    COUNT(*) AS occurrences 
FROM StringBenchmark 
GROUP BY benchmark_string
ORDER BY occurrences DESC 
LIMIT 10;
