SELECT
    CONCAT('Supplier: ', s.s_name, ', for Part: ', p.p_name, ' (', p.p_partkey, ') - ', 
           'Total Quantity Supplied: ', SUM(ps.ps_availqty), 
           ', Region: ', r.r_name)
FROM
    partsupp ps
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    p.p_name LIKE '%widget%'
GROUP BY
    s.s_name, p.p_name, p.p_partkey, r.r_name
HAVING
    SUM(ps.ps_availqty) > 100
ORDER BY
    SUM(ps.ps_availqty) DESC;
