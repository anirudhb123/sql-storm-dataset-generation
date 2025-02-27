WITH PartInfo AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        CONCAT(p.p_brand, ' - ', p.p_type) AS part_description,
        p.p_size,
        p.p_retailprice,
        p.p_comment
    FROM part p
    WHERE LENGTH(p.p_name) > 10
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        REGEXP_REPLACE(s.s_address, '[^a-zA-Z0-9 ]', '') AS clean_address,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    WHERE s.s_acctbal > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(li.l_orderkey) AS line_count,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT
    pi.p_partkey,
    pi.part_description,
    si.s_name,
    oi.o_orderkey,
    oi.o_orderstatus,
    oi.line_count,
    oi.total_revenue,
    SUBSTRING(pi.p_comment, 1, 15) AS short_comment
FROM PartInfo pi
JOIN SupplierInfo si ON si.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = pi.p_partkey LIMIT 1)
JOIN OrderSummary oi ON oi.line_count > 1
ORDER BY oi.total_revenue DESC, pi.p_retailprice ASC
LIMIT 50;
