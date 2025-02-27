WITH SupplierDetails AS (
    SELECT 
        s_name,
        s_address,
        s_phone,
        SUBSTRING(s_comment, 1, 20) AS short_comment,
        CHAR_LENGTH(s_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY s_nationkey ORDER BY s_acctbal DESC) AS rank_per_nation
    FROM 
        supplier
), 
NationSummary AS (
    SELECT 
        n_name AS nation_name,
        COUNT(s_suppkey) AS total_suppliers,
        AVG(s_acctbal) AS avg_account_balance,
        MAX(s_acctbal) AS max_account_balance
    FROM 
        supplier
    JOIN 
        nation ON supplier.s_nationkey = nation.n_nationkey
    GROUP BY 
        n_name
)
SELECT 
    ns.nation_name,
    ns.total_suppliers,
    ns.avg_account_balance,
    ns.max_account_balance,
    sd.s_name,
    sd.s_address,
    sd.s_phone,
    sd.short_comment,
    sd.comment_length,
    sd.rank_per_nation
FROM 
    NationSummary ns
JOIN 
    SupplierDetails sd ON ns.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_name = sd.s_name))
WHERE 
    sd.rank_per_nation <= 3
ORDER BY 
    ns.nation_name, sd.rank_per_nation;
