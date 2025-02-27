SELECT 
    s_name AS Supplier_Name,
    p_name AS Part_Name,
    CONCAT('Supplier: ', s_name, ', Part: ', p_name, ', Available Quantity: ', CAST(ps_availqty AS VARCHAR), ', Supply Cost: $', FORMAT(ps_supplycost, 2)) AS Supply_Info,
    TRIM(CONCAT(n_name, ' - ', r_name)) AS Location_Info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(s_name) BETWEEN 5 AND 15
  AND 
    p_type LIKE '%soft%'
ORDER BY 
    p_retailprice DESC
LIMIT 20;
