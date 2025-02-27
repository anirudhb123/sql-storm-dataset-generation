WITH StringProcessing AS (
    SELECT 
        p.p_name, 
        CONCAT('Part Name: ', p.p_name, ' | Brand: ', p.p_brand, ' | Type: ', p.p_type) AS part_details,
        REPLACE(p.p_comment, 'obsolete', 'updated') AS updated_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 10
),
SupplierDetails AS (
    SELECT 
        s.s_name, 
        TRIM(s.s_address) AS trimmed_address, 
        SUBSTRING(s.s_phone FROM 3 FOR 5) AS phone_segment,
        s.s_comment
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
),
OrderGroup AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS line_count, 
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sp.p_name,
    sp.part_details,
    sd.s_name,
    sd.trimmed_address,
    og.line_count,
    og.total_extended_price,
    CASE 
        WHEN og.total_extended_price > 5000 THEN 'High Value'
        ELSE 'Standard Value'
    END AS order_value_category
FROM 
    StringProcessing sp
JOIN 
    SupplierDetails sd ON LENGTH(sp.part_details) > 40
JOIN 
    OrderGroup og ON og.line_count > 5
ORDER BY 
    og.total_extended_price DESC;
