WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level, NULL AS parent_suppkey
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE 'A%'))
    
    UNION ALL
    
    SELECT s2.s_suppkey, s2.s_name, sc.level + 1, sc.s_suppkey
    FROM supplier s2
    JOIN supplier_chain sc ON sc.s_suppkey = s2.s_suppkey
    WHERE s2.s_acctbal < (SELECT MAX(s_acctbal) FROM supplier) / (sc.level + 1)
)

SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS total_filled_orders,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' - ', p.p_comment), '; ') FILTER (WHERE p.p_retailprice IS NOT NULL) AS part_details,
    AVG(l.l_extendedprice * (1 - l.l_discount) * (CASE WHEN l.l_returnflag = 'N' THEN 1 ELSE 0 END)) AS avg_net_price
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    supplier_chain sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
WHERE 
    (c.c_acctbal IS NOT NULL OR sc.parent_suppkey IS NOT NULL)
    AND (l.l_shipdate, l.l_receiptdate) BETWEEN '2022-01-01' AND CURRENT_DATE
    AND sc.level <= 3
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    customer_count DESC, total_filled_orders ASC NULLS LAST
;
