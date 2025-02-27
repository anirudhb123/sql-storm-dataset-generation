WITH part_details AS (
    SELECT 
        p_partkey,
        UPPER(p_name) AS upper_name,
        SUBSTRING(p_comment, 1, 10) AS short_comment,
        REPLACE(p_brand, 'BrandA', 'BrandX') AS modified_brand
    FROM part
), supplier_nation AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        CONCAT(n.n_name, '-', s.s_name) AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), lineitem_summary AS (
    SELECT 
        l_orderkey,
        COUNT(*) AS total_lineitems,
        SUM(l_extendedprice) AS total_value
    FROM lineitem
    GROUP BY l_orderkey
), order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        ps.ps_suppkey,
        CONCAT('Order-', o.o_orderkey) AS order_label
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
)
SELECT 
    pd.p_partkey,
    pd.upper_name,
    pd.short_comment,
    pd.modified_brand,
    sn.supplier_nation,
    os.order_label,
    ls.total_lineitems,
    ls.total_value
FROM part_details pd
JOIN order_summary os ON pd.p_partkey = os.ps_suppkey
JOIN lineitem_summary ls ON os.o_orderkey = ls.l_orderkey
JOIN supplier_nation sn ON os.ps_suppkey = sn.s_suppkey
WHERE ls.total_value > 1000
ORDER BY pd.upper_name, sn.nation_name;
