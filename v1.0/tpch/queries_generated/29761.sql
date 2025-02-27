SELECT 
    CONCAT('Supplier: ', s.s_name, ' (', s.s_acctbal, ') - ',
           'Nation: ', n.n_name, ' - ',
           'Part: ', p.p_name, ' (', p.p_size, ' ', p.p_container, ') - ',
           'Order Date: ', DATE_FORMAT(o.o_orderdate, '%Y-%m-%d'), ' - ',
           'Total Price: ', FORMAT(o.o_totalprice, 2), ' - ',
           'Comment: ', l.l_comment) AS detailed_info
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
    n.n_name LIKE '%United%' 
    AND o.o_orderstatus = 'O'
ORDER BY 
    s.s_name, o.o_orderdate DESC
LIMIT 100;
