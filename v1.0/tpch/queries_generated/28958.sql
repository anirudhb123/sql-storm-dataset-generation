WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        CONCAT(s.s_name, ' ', s.s_phone) AS contact_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        UPPER(p.p_mfgr) AS mfgr_upper,
        CONCAT(SUBSTR(p.p_name, 1, 10), '...') AS name_preview,
        (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) AS supply_count
    FROM 
        part p
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS line_item_count,
        MAX(o.o_orderdate) AS last_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    s.contact_info,
    p.name_preview,
    p.mfgr_upper,
    o.total_sales,
    SUM(o.line_item_count) AS total_line_items,
    MAX(o.last_order_date) AS recent_order
FROM 
    region r
JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    PartDetails p ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
JOIN 
    OrderSummary o ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY 
    r.r_name, n.n_name, s.contact_info, p.name_preview, p.mfgr_upper
ORDER BY 
    total_sales DESC, region_name, nation_name;
