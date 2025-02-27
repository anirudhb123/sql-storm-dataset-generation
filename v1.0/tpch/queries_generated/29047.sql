WITH supplier_details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_nationkey,
        s.s_acctbal,
        CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
),
part_info AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_container,
        CONCAT('Part: ', p.p_name, ', Brand: ', p.p_brand, ', Type: ', p.p_type) AS part_description
    FROM 
        part p
),
line_details AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        CONCAT('OrderKey: ', l.l_orderkey, ', PartKey: ', l.l_partkey, ', Quantity: ', l.l_quantity) AS line_info
    FROM 
        lineitem l
)
SELECT 
    sd.s_name,
    sd.s_address,
    pi.part_description,
    ld.line_info,
    sd.comment_length,
    COUNT(ld.l_orderkey) AS order_count
FROM 
    supplier_details sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    part_info pi ON ps.ps_partkey = pi.p_partkey
JOIN 
    line_details ld ON ld.l_partkey = pi.p_partkey
GROUP BY 
    sd.s_suppkey, sd.s_name, sd.s_address, pi.part_description, ld.line_info, sd.comment_length
ORDER BY 
    sd.comment_length DESC, sd.s_name;
