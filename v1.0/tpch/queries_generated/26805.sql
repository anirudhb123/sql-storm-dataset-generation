WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        SUBSTRING(p.p_comment, 1, 10) AS short_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length
    FROM part p
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address) AS full_info,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS cleaned_comment
    FROM supplier s
),
OrdersWithInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        CONVERT(DATE_FORMAT(o.o_orderdate, '%Y-%m'), CHAR) AS order_month,
        (SELECT COUNT(*) FROM lineitem WHERE l_orderkey = o.o_orderkey) AS lineitem_count
    FROM orders o
)
SELECT 
    pi.p_name,
    pi.p_mfgr,
    si.full_info,
    wi.order_month,
    SUM(wi.lineitem_count) AS total_lineitems,
    AVG(pi.p_retailprice) AS avg_retail_price,
    COUNT(DISTINCT si.s_suppkey) AS distinct_suppliers,
    COUNT(DISTINCT wi.o_orderkey) AS unique_orders
FROM PartInfo pi
JOIN SupplierInfo si ON pi.p_partkey = si.s_nationkey
JOIN OrdersWithInfo wi ON si.s_suppkey = wi.o_orderkey
WHERE pi.comment_length > 20
GROUP BY pi.p_name, pi.p_mfgr, si.full_info, wi.order_month
HAVING AVG(pi.p_retailprice) > 50.00
ORDER BY total_lineitems DESC, pi.p_name;
