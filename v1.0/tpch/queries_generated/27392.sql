SELECT 
    s.s_name AS Supplier_Name,
    p.p_name AS Part_Name,
    CONCAT('Supplier: ', s.s_name, ', provides part: ', p.p_name, ', with a retail price of $', FORMAT(p.p_retailprice, 2), '.') AS Detail_Description,
    SUBSTRING_INDEX(GROUP_CONCAT(DISTINCT r.r_name ORDER BY r.r_name SEPARATOR ', '), ',', 3) AS Top_Regions,
    COUNT(DISTINCT c.c_custkey) AS Unique_Customers,
    SUM(l.l_quantity) AS Total_Quantity_Sold,
    AVG(l.l_extendedprice) AS Average_Extended_Price
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 30 
    AND l.l_shipdate > DATE_SUB(CURRENT_DATE, INTERVAL 1 YEAR)
GROUP BY 
    s.s_suppkey, p.p_partkey 
ORDER BY 
    Total_Quantity_Sold DESC, Average_Extended_Price DESC
LIMIT 10;
