SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS supplier_part_name,
    SUBSTRING_INDEX(s.s_address, ' ', 1) AS address_first_word,
    REPLACE(CONCAT('Region: ', r.r_name, '; Nation: ', n.n_name), ' ', '-') AS region_nation_combination,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(o.o_orderkey) AS total_orders
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    orders o ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
JOIN 
    region r ON r.r_regionkey = n.n_regionkey
WHERE 
    p.p_retailprice > 50.00 AND 
    s.s_acctbal >= 1000.00
GROUP BY 
    supplier_part_name, address_first_word, region_nation_combination
HAVING 
    total_orders > 10
ORDER BY 
    comment_length DESC, total_orders ASC;
