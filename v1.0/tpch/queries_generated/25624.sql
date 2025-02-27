SELECT 
    concat('Supplier Name: ', s.s_name, ' | Part Name: ', p.p_name) AS supplier_part_info,
    substr(p.p_comment, 1, 20) AS part_comment_summary,
    s.s_phone,
    CASE 
        WHEN SUM(ps.ps_availqty) > 100 
        THEN 'Available in Large Quantity'
        WHEN SUM(ps.ps_availqty) BETWEEN 51 AND 100 
        THEN 'Available in Moderate Quantity'
        ELSE 'Limited Availability' 
    END AS availability_status,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost) DESC) AS supplier_rank
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_type LIKE '%metal%'
GROUP BY 
    s.s_suppkey, p.p_name, s.s_phone
HAVING 
    SUM(ps.ps_supplycost) > 5000
ORDER BY 
    supplier_rank;
