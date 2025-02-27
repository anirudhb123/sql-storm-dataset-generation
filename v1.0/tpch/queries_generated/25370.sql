WITH String_Details AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS upper_name,
        LOWER(p.p_name) AS lower_name,
        CONCAT('Part: ', p.p_name, ' | Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS description,
        REPLACE(p.p_comment, ' ', '-') AS comment_with_dashes,
        CHARINDEX('Part', p.p_comment) AS part_occurrence
    FROM 
        part p
), Supplier_Details AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.n_nationkey,
        LEFT(s.s_name, 10) AS short_name,
        SUBSTRING(s.s_comment, 1, 50) AS brief_comment
    FROM 
        supplier s
), Order_Summary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice) AS total_extended_price,
        AVG(l.l_discount) AS average_discount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice
)
SELECT 
    sd.p_partkey,
    sd.name_length,
    sd.upper_name,
    sd.lower_name,
    sd.description,
    sd.comment_with_dashes,
    sd.part_occurrence,
    su.s_name AS supplier_name,
    su.short_name,
    su.brief_comment,
    os.o_orderkey,
    os.lineitem_count,
    os.total_extended_price,
    os.average_discount
FROM 
    String_Details sd
JOIN 
    Supplier_Details su ON sd.p_partkey = su.n_nationkey
JOIN 
    Order_Summary os ON su.s_suppkey = os.o_custkey
WHERE 
    sd.part_occurrence > 0
ORDER BY 
    sd.name_length DESC, os.total_extended_price DESC;
