WITH processed_parts AS (
    SELECT 
        p.p_partkey,
        UPPER(p.p_name) AS upper_name,
        LENGTH(p.p_comment) AS comment_length,
        SUBSTRING_INDEX(p.p_container, ' ', 1) AS first_container_word
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
extended_supplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        CONCAT(s.s_name, ' - ', UPPER(s.s_address)) AS supplier_info,
        JSON_OBJECT('name', s.s_name, 'address', s.s_address) AS supplier_json
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    LEFT JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pp.upper_name, 
    ps.supplier_info, 
    os.total_price, 
    os.unique_parts, 
    os.o_orderkey
FROM 
    processed_parts pp
JOIN 
    extended_supplier ps ON pp.p_partkey = ps.s_suppkey
JOIN 
    order_summary os ON os.o_orderkey = pp.p_partkey
WHERE 
    pp.comment_length > 15
ORDER BY 
    os.total_price DESC 
LIMIT 10;
