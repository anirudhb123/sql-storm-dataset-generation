WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment,
        LENGTH(s.s_name) AS name_length,
        LENGTH(s.s_address) AS address_length,
        REGEXP_REPLACE(s.s_comment, '[^a-zA-Z0-9 ]', '') AS sanitized_comment,
        CHAR_LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_size,
        LENGTH(p.p_name) AS name_length,
        p.p_comment,
        CHAR_LENGTH(p.p_comment) AS comment_length,
        SUBSTRING(p.p_comment FROM 1 FOR 10) AS comment_preview
    FROM 
        part p
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(o.o_orderdate) AS last_order_date,
        MIN(o.o_orderdate) AS first_order_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    sd.s_acctbal,
    pd.p_name,
    pd.name_length AS part_name_length,
    os.total_revenue,
    os.part_count,
    os.first_order_date,
    os.last_order_date,
    pd.comment_preview
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummaries os ON os.o_orderkey = (SELECT o.o_orderkey 
                                            FROM orders o 
                                            JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
                                            WHERE l.l_partkey = pd.p_partkey 
                                            ORDER BY o.o_orderdate DESC 
                                            LIMIT 1)
WHERE 
    sd.s_acctbal > 1000
ORDER BY 
    sd.s_name, os.total_revenue DESC;
