WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name, 
        r.r_name AS region_name, 
        s.s_acctbal, 
        LENGTH(s.s_comment) AS comment_length,
        SUBSTRING(s.s_comment FROM 1 FOR 20) AS short_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        LENGTH(p.p_comment) AS comment_length,
        CONCAT(SUBSTRING(p.p_comment FROM 1 FOR 10), '...') AS short_comment
    FROM part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_totalprice, 
        o.o_orderdate, 
        COUNT(l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    os.o_orderkey,
    os.o_orderstatus,
    os.o_totalprice,
    os.total_lines,
    sd.comment_length AS supplier_comment_length,
    pd.comment_length AS part_comment_length,
    sd.short_comment AS supplier_short_comment,
    pd.short_comment AS part_short_comment
FROM SupplierDetails sd
JOIN PartDetails pd ON sd.s_suppkey = pd.p_partkey
JOIN OrderSummary os ON os.o_totalprice > 1000
WHERE sd.s_acctbal > 5000
ORDER BY sd.s_name, pd.p_name;
