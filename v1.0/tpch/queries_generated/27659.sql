SELECT
    CONCAT(
        'Supplier: ', s_name, 
        ', Address: ', s_address, 
        ', Nation: ', n_name, 
        ', Part: ', p_name, 
        ', Type: ', p_type, 
        ', Retail Price: $', FORMAT(p_retailprice, 2), 
        ', Order Total: $', FORMAT(SUM(l_extendedprice * (1 - l_discount)), 2)
    ) AS supplier_details
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate >= '2023-01-01'
    AND o.o_orderdate < '2024-01-01'
GROUP BY
    s.s_name, s.s_address, n.n_name, p.p_name, p.p_type, p.p_retailprice
ORDER BY
    SUM(l_extendedprice * (1 - l_discount)) DESC
LIMIT 10;
