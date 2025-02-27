SELECT
    p.p_brand,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    CONCAT(r.r_name, ' - ', n.n_name) AS region_nation
FROM
    part p
JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    p.p_comment LIKE '%special%'
    AND o.o_orderstatus = 'O'
    AND l.l_shipmode IN ('AIR', 'TRUCK')
GROUP BY
    p.p_brand, region_nation
HAVING
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY
    total_available_quantity DESC;
