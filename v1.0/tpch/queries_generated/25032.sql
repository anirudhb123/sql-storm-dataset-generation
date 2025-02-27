SELECT
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name, ', Quantity: ', ps.ps_availqty, 
           ', Price: $', FORMAT(ps.ps_supplycost, 2), ', Comment: ', ps.ps_comment) AS detailed_info
FROM
    supplier s
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    LENGTH(p.p_name) > 10 AND
    s.s_acctbal > 1000
ORDER BY
    ps.ps_supplycost DESC
LIMIT 100;
