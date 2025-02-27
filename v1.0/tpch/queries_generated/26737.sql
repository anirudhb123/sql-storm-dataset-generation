SELECT 
    CONCAT('Part: ', p_name, ' | Supplier: ', s_name, 
           ' | Quantity: ', CAST(ps_availqty AS VARCHAR), 
           ' | Price: $', CAST(ps_supplycost AS VARCHAR), 
           ' | Order Date: ', TO_CHAR(o_orderdate, 'YYYY-MM-DD'), 
           ' | Customer: ', c_name) AS bench_mark_result
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND s.s_acctbal > 1000
    AND o.o_orderstatus = 'O'
    AND l.l_shipdate >= DATE '2023-01-01'
ORDER BY 
    c.c_name DESC
FETCH FIRST 100 ROWS ONLY;
