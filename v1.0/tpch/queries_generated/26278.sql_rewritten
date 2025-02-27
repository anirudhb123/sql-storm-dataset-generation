SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS suppliers_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_discount 
        ELSE NULL 
    END) AS avg_discount_returned,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_providing_parts,
    MIN(CASE 
        WHEN o.o_orderstatus = 'O' THEN o.o_orderdate 
        ELSE NULL 
    END) AS earliest_order_date
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_size BETWEEN 1 AND 20
    AND o.o_orderdate >= '1996-01-01'
    AND o.o_orderdate < '1997-01-01'
GROUP BY 
    p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 10;