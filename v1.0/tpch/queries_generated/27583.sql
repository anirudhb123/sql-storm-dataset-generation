SELECT 
    CONCAT(s.s_name, ' of ', p.p_name) AS supplier_product_name,
    SUBSTR(n.n_name, 1, 5) AS nation_prefix,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    customer c ON EXISTS (SELECT 1 FROM orders o WHERE o.o_custkey = c.c_custkey 
                           AND o.o_orderstatus = 'O' 
                           AND o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31')
WHERE 
    p.p_size BETWEEN 1 AND 50
  AND 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
GROUP BY 
    supplier_product_name, nation_prefix, comment_length
HAVING 
    AVG(o.o_totalprice) > 1000
ORDER BY 
    nation_prefix ASC, comment_length DESC
LIMIT 100;
