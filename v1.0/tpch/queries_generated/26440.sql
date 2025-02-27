SELECT
    CONCAT('Part Name: ', p_name, ' | Manufacturer: ', p_mfgr, ' | Type: ', p_type) AS part_info,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(p.p_retailprice) AS max_retail_price,
    TRIM(LEADING 'Brand ' FROM p_brand) AS trimmed_brand,
    SUBSTRING_INDEX(p_comment, ' ', 3) AS comment_snippet,
    LEFT(p_container, 5) AS short_container,
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    lineitem l ON l.l_partkey = p.p_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p_size > 5 AND r.r_name LIKE 'S%'
GROUP BY
    p.p_partkey, r.r_name
HAVING
    AVG(l.l_discount) < 0.05
ORDER BY
    supplier_count DESC, avg_extended_price DESC
LIMIT 100;
