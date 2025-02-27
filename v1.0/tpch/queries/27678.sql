
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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS RankByPrice
    FROM 
        part p
), 
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        SUBSTRING(s.s_comment, POSITION('limited' IN s.s_comment) + 8, 20) AS LimitedComment
    FROM 
        supplier s
    WHERE 
        s.s_comment LIKE '%limited%'
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_availqty,
        ps.ps_supplycost,
        p.p_name,
        s.LimitedComment
    FROM 
        partsupp ps
    JOIN 
        RankedParts p ON ps.ps_partkey = p.p_partkey
    JOIN 
        SupplierDetails s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    p.p_name,
    COUNT(ps.ps_suppkey) AS TotalSuppliers,
    MAX(ps.ps_supplycost) AS MaxSupplyCost,
    MIN(ps.ps_supplycost) AS MinSupplyCost,
    SUM(ps.ps_availqty) AS TotalAvailableQty,
    STRING_AGG(DISTINCT ps.LimitedComment, '; ') AS AggregatedComments
FROM 
    PartSupplier ps
JOIN 
    RankedParts p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.RankByPrice <= 5
GROUP BY 
    p.p_name
ORDER BY 
    TotalSuppliers DESC, MaxSupplyCost ASC;
