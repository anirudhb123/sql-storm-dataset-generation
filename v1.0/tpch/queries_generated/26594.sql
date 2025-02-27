SELECT 
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_availqty,
    AVG(ps.ps_supplycost) AS avg_supplycost,
    MIN(DATE_FORMAT(o.o_orderdate, '%Y-%m')) AS earliest_order_month,
    MAX(DATE_FORMAT(o.o_orderdate, '%Y-%m')) AS latest_order_month,
    RTRIM(CONCAT('Total Availability: ', CAST(SUM(ps.ps_availqty) AS CHAR))) AS availability_info
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
WHERE 
    p.p_mfgr LIKE 'Manufacturer%'' 
    AND s.s_acctbal > 100.00 
    AND o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
GROUP BY 
    p.p_brand
ORDER BY 
    supplier_count DESC, total_availqty DESC;
