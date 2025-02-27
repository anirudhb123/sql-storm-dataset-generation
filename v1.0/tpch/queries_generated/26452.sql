SELECT 
    CONCAT(
        'Part: ', p.p_name, 
        ' (', p.p_partkey, ') Manufactured by ', p.p_mfgr, 
        ' (Brand: ', p.p_brand, '), Type: ', p.p_type, 
        ', Size: ', p.p_size, 
        ', Price: $', FORMAT(p.p_retailprice, 2), 
        ', Comment: ', p.p_comment, 
        ' | Supplier Info: ', s.s_name, 
        ' (', s.s_address, ', Phone: ', s.s_phone, 
        ', Balance: $', FORMAT(s.s_acctbal, 2), 
        ', Comment: ', s.s_comment, 
        ') | Order Details: ', o.o_orderkey, 
        ' (Status: ', o.o_orderstatus, ', Total: $', FORMAT(o.o_totalprice, 2), 
        ', Priority: ', o.o_orderpriority, 
        ', Comment: ', o.o_comment, 
        ')'
    ) AS string_benchmark
FROM 
    part AS p
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier AS s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_retailprice > 50.00 
    AND s.s_acctbal < 5000.00
ORDER BY 
    p.p_name, s.s_name, o.o_orderdate DESC
LIMIT 100;
