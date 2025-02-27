WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        LENGTH(p.p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY LENGTH(p.p_comment) DESC) AS rank
    FROM 
        part p
    WHERE 
        p.p_size >= 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 50) AS short_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
SalesInfo AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.p_type,
    sd.s_name AS supplier_name,
    sd.short_comment,
    si.lineitem_count,
    si.total_sales,
    rp.comment_length
FROM 
    RankedParts rp
JOIN 
    SupplierDetails sd ON rp.rank = 1
JOIN 
    SalesInfo si ON si.lineitem_count > 5
WHERE 
    rp.comment_length > 20
ORDER BY 
    si.total_sales DESC, rp.p_name ASC
LIMIT 100;
