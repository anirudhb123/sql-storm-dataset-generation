
SELECT 
    CONCAT_WS(' - ', p.p_name, s.s_name, CONCAT('(${:.2f})', ps.ps_supplycost)) AS part_supplier_cost,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    MIN(CASE WHEN l.l_returnflag = 'N' THEN l.l_shipdate END) AS first_shipped_date,
    MAX(l.l_shipdate) AS last_shipped_date,
    STRING_AGG(DISTINCT CONCAT_WS(' | ', c.c_name, c.c_acctbal), ', ') AS customers_info
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
    s.s_comment LIKE '%special%'
GROUP BY 
    p.p_name, s.s_name, ps.ps_supplycost, p.p_partkey, s.s_suppkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    total_returned_quantity DESC, first_shipped_date ASC;
