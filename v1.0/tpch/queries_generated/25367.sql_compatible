
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) - LENGTH(REPLACE(p.p_name, 'steel', '')) > 0
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supp_rank
    FROM 
        supplier s
    WHERE 
        CHAR_LENGTH(s.s_comment) > 50
),
OrdersInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        LEFT(o.o_comment, 30) AS short_comment
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
),
AggregateData AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        si.s_name,
        oi.o_orderkey,
        oi.o_orderdate,
        oi.short_comment
    FROM 
        RankedParts rp
    JOIN 
        partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN 
        SupplierInfo si ON ps.ps_suppkey = si.s_suppkey AND si.supp_rank <= 5
    JOIN 
        lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN 
        OrdersInfo oi ON li.l_orderkey = oi.o_orderkey
)
SELECT 
    ad.p_partkey,
    ad.p_name,
    COUNT(DISTINCT ad.o_orderkey) AS total_orders,
    AVG(ad.p_retailprice) AS avg_retail_price,
    STRING_AGG(ad.s_name, ', ') AS supplier_names,
    MIN(ad.o_orderdate) AS first_order_date,
    MAX(ad.o_orderdate) AS last_order_date,
    STRING_AGG(ad.short_comment, '; ') AS comments_concatenated
FROM 
    AggregateData ad
GROUP BY 
    ad.p_partkey, ad.p_name
ORDER BY 
    total_orders DESC, avg_retail_price DESC;
