WITH PartDetails AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SPLIT_PART(p.p_comment, ' ', 1) AS first_word_comment,
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(p.p_mfgr, ' - ', p.p_brand) AS mfgr_brand,
        LOWER(p.p_name) AS lower_name
    FROM 
        part p
), SupplierNation AS (
    SELECT 
        s.s_name,
        n.n_name,
        s.s_acctbal,
        CONCAT(s.s_name, ' in ', n.n_name) AS supplier_nation
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), HighValueCustomers AS (
    SELECT 
        c.c_name,
        c.c_acctbal,
        SUBSTRING(c.c_address FROM 1 FOR 15) AS address_short,
        CASE
            WHEN c.c_acctbal >= 10000 THEN 'High Value'
            ELSE 'Regular'
        END AS customer_type
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL
)
SELECT 
    pd.p_name,
    pd.mfgr_brand,
    sn.supplier_nation,
    hvc.c_name,
    hvc.customer_type,
    hvc.address_short,
    pd.comment_length
FROM 
    PartDetails pd
JOIN 
    partsupp ps ON pd.p_partkey = ps.ps_partkey
JOIN 
    SupplierNation sn ON ps.ps_suppkey = sn.s_suppkey
JOIN 
    orders o ON ps.ps_partkey = o.o_orderkey
JOIN 
    HighValueCustomers hvc ON o.o_custkey = hvc.c_custkey
WHERE 
    pd.first_word_comment LIKE 'A%'
ORDER BY 
    pd.comment_length DESC, 
    hvc.c_acctbal DESC
LIMIT 100;
