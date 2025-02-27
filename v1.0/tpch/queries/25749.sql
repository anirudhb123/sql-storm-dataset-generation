SELECT 
    SPLIT_PART(p.p_name, ' ', 1) AS first_word,
    COUNT(*) AS part_count,
    AVG(p.p_retailprice) AS avg_retail_price,
    MIN(s.s_acctbal) AS min_supplier_balance,
    MAX(s.s_acctbal) AS max_supplier_balance,
    STRING_AGG(DISTINCT n.n_name, ', ') AS nations_supplied,
    STRING_AGG(DISTINCT c.c_name, '; ') AS customers,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice ELSE 0 END) AS total_sales_fully_shipped
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%steel%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    first_word
ORDER BY 
    part_count DESC
LIMIT 10;