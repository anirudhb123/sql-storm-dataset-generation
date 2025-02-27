WITH FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        CONCAT(p.p_mfgr, ' - ', p.p_name) AS part_description,
        LENGTH(TRIM(p.p_comment)) AS comment_length
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 30
      AND p.p_comment LIKE '%urgent%'
),
SupplierData AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUBSTRING(s.s_address FROM 1 FOR 20) AS short_address,
        LENGTH(REPLACE(s.s_comment, ' ', '')) AS comment_length
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
      AND s.s_comment IS NOT NULL
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice - l.l_discount) AS total_value,
        MAX(o.o_orderdate) AS latest_order_date
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    fp.p_partkey,
    fp.part_description,
    sd.s_name,
    sd.short_address,
    os.line_item_count,
    os.total_value,
    os.latest_order_date
FROM FilteredParts fp
JOIN SupplierData sd ON sd.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey ORDER BY ps.ps_supplycost DESC LIMIT 1)
JOIN OrderSummary os ON os.line_item_count > 0
WHERE fp.comment_length > 10
ORDER BY os.total_value DESC, fp.p_partkey ASC
LIMIT 100;
