
SELECT 
    p.p_name AS part_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_quantity 
        ELSE 0 
    END) AS total_returned_quantity,
    AVG(l.l_extendedprice) AS average_extended_price,
    MAX(CASE 
        WHEN c.c_mktsegment = 'AUTOMOBILE' THEN l.l_discount 
        END) AS max_discount_automobile,
    STRING_AGG(DISTINCT r.r_name, ', ') AS regions_supplied,
    CONCAT(p.p_name, ' (', p.p_mfgr, ')') AS part_description
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
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, p.p_mfgr
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY 
    total_returned_quantity DESC, average_extended_price ASC;
