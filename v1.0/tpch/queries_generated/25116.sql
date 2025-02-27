WITH RankedParts AS (
    SELECT 
        p_name,
        p_mfgr,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rnk
    FROM 
        part
),
FilteredParts AS (
    SELECT 
        p_name,
        p_mfgr,
        p_type,
        p_size,
        p_container,
        p_retailprice
    FROM 
        RankedParts
    WHERE 
        rnk <= 10
),
SupplierDetail AS (
    SELECT 
        s.s_name,
        s.s_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment,
        f.p_name,
        f.p_container
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        FilteredParts f ON ps.ps_partkey = f.p_partkey
)
SELECT 
    s.s_name AS SupplierName,
    COUNT(f.p_name) AS ProductCount,
    SUM(s.s_acctbal) AS TotalAccountBalance,
    STRING_AGG(CONCAT(f.p_name, ' (', f.p_container, ')'), ', ') AS ProductsSupplied
FROM 
    SupplierDetail s
JOIN 
    FilteredParts f ON s.p_name = f.p_name
GROUP BY 
    s.s_name
ORDER BY 
    TotalAccountBalance DESC;
