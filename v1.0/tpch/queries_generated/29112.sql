SELECT 
    CONCAT(s.s_name, ' from ', s.s_address) AS Supplier_Info,
    SUBSTRING_INDEX(p.p_name, ' ', 1) AS Primary_Part_Name,
    LENGTH(p.p_name) AS Part_Name_Length,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_partkey = p.p_partkey) AS Total_Lines,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    s.s_comment LIKE '%urgent%'
GROUP BY 
    s.s_suppkey, p.p_partkey
HAVING 
    AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    Part_Name_Length DESC, Supplier_Info;
