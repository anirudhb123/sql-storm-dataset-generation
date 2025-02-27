SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey,
    o.o_orderdate,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(CASE 
            WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE 0 
        END) AS total_revenue_returned,
    AVG(p.p_retailprice) AS avg_retail_price,
    STRING_AGG(DISTINCT CONCAT(c.c_address, ' ', c.c_phone), '; ') AS customer_details,
    STRING_AGG(DISTINCT CONCAT(s.s_address, ' ', s.s_phone), '; ') AS supplier_details
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
    p.p_mfgr LIKE 'Manufacturer%'
    AND o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate
ORDER BY 
    total_revenue_returned DESC
LIMIT 10;