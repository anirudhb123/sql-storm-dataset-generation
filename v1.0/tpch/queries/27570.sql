SELECT 
    CONCAT(s.s_name, ' ', s.s_address) AS Supplier_Details,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS Location_Info,
    COUNT(DISTINCT ps.ps_partkey) AS Total_Parts_Supplied,
    SUM(ps.ps_availqty) AS Total_Quantity_Available,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    STRING_AGG(DISTINCT p.p_name, ', ') AS Part_Names_Supplied
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
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND s.s_acctbal > 1000
GROUP BY 
    s.s_name, s.s_address, r.r_name, n.n_name
ORDER BY 
    Location_Info DESC, Total_Quantity_Available DESC;
