WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        s.s_phone,
        s.s_acctbal,
        s.s_comment
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        MAX(o.o_orderdate) AS latest_order_date,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_size, p.p_retailprice, p.p_comment
)
SELECT 
    sd.s_name AS supplier_name,
    sd.nation_name,
    ps.p_name AS part_name,
    ps.p_brand,
    ps.supplier_count,
    os.o_orderkey,
    os.total_revenue,
    os.latest_order_date,
    os.line_item_count
FROM SupplierDetails sd
JOIN OrderSummary os ON sd.s_suppkey = os.o_orderkey
JOIN PartDetails ps ON os.line_item_count = ps.supplier_count
WHERE ps.p_retailprice > 50.00
ORDER BY total_revenue DESC, sd.s_name ASC;
