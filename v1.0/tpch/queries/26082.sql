
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    STRING_AGG(DISTINCT CASE WHEN l.l_linestatus = 'F' THEN s.s_name END, ', ') AS fulfilled_suppliers,
    MAX(o.o_orderdate) AS latest_order_date
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    p.p_brand,
    p.p_comment
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_returned_quantity DESC, p.p_name ASC;
