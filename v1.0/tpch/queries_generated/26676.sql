SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    SUM(ps.ps_availqty) AS total_avail_qty,
    AVG(s.s_acctbal) AS avg_acct_bal,
    MAX(l.l_extendedprice) AS max_extended_price,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', s.s_comment), '; ') AS supplier_comments,
    REPLACE(REPLACE(p.p_comment, 'small', 'compact'), 'large', 'spacious') AS updated_part_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(ps.ps_availqty) > 100
ORDER BY 
    total_avail_qty DESC, avg_acct_bal DESC;
