SELECT
    CONCAT('Supplier Name: ', s.s_name, ' | Part Name: ', p.p_name, 
           ' | Order Amount: ', SUM(l.l_extendedprice * (1 - l.l_discount)),
           ' | Order Count: ', COUNT(DISTINCT o.o_orderkey)) AS OrderSummary
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
WHERE s.s_comment LIKE '%regular%'
AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY s.s_name, p.p_name
HAVING COUNT(o.o_orderkey) > 5
ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC
LIMIT 10;