SELECT
    CONCAT('Supplier: ', s_name, ' | Nation: ', n_name, ' | Product: ', p_name, 
           ' | Total Supply Cost: ', SUM(ps_supplycost * ps_availqty), 
           ' | Comments: ', LEFT(ps_comment, 50), '...') AS supplier_info
FROM
    supplier s
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE
    LENGTH(p_name) > 20 AND 
    n_name LIKE '%land%' AND 
    ps_supplycost > (
        SELECT AVG(ps_supplycost) FROM partsupp
    )
GROUP BY
    s.s_suppkey, n.n_nationkey, p.p_partkey
ORDER BY
    SUM(ps_supplycost * ps_availqty) DESC
LIMIT 10;
