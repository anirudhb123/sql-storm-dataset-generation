
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    (SELECT COUNT(DISTINCT l2.l_orderkey) 
     FROM lineitem l2 
     WHERE l2.l_partkey = p.p_partkey) AS lineitem_count,
    CASE 
        WHEN SUM(l.l_quantity) > 1000 THEN 'High Demand'
        WHEN SUM(l.l_quantity) BETWEEN 500 AND 1000 THEN 'Medium Demand'
        ELSE 'Low Demand'
    END AS demand_category,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment
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
    p.p_retailprice > 50 
    AND s.s_acctbal <= 1000
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, s.s_name, c.c_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 10
ORDER BY 
    total_quantity DESC, avg_price ASC;
