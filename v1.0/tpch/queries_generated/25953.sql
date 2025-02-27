WITH DetailedParts AS (
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
        CONCAT(REPLACE(p.p_name, ' ', ''), '_', p.p_brand) AS processed_name,
        LENGTH(p.p_comment) AS comment_length
    FROM part p
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address,
        n.n_name AS nation_name,
        LENGTH(s.s_comment) AS supplier_comment_length,
        s.s_acctbal
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        COUNT(l.l_orderkey) AS line_item_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT 
    dp.processed_name,
    dp.comment_length,
    sd.s_name,
    sd.nation_name,
    os.line_item_count,
    os.total_revenue,
    os.unique_suppliers
FROM DetailedParts dp
JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = dp.p_partkey
)
JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = dp.p_partkey
)
WHERE dp.p_retailprice > 100.00 
ORDER BY total_revenue DESC, comment_length DESC;
