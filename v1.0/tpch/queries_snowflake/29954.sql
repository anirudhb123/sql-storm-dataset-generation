WITH RankedParts AS (
    SELECT 
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        SUM(ps.ps_availqty) AS total_available,
        AVG(p.p_retailprice) AS avg_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_availqty) DESC) AS rnk
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_name, p.p_mfgr, p.p_brand, p.p_type
),
TopAvailableParts AS (
    SELECT 
        rnk, 
        p_name, 
        p_mfgr, 
        p_brand, 
        p_type, 
        total_available, 
        avg_price
    FROM 
        RankedParts
    WHERE 
        rnk <= 5
)
SELECT 
    t1.p_name AS Part_Name,
    t1.p_mfgr AS Manufacturer,
    t1.p_brand AS Brand,
    t1.p_type AS Type,
    t1.total_available AS Total_Available_Quantity,
    t1.avg_price AS Average_Price,
    SUM(o.o_totalprice) AS Total_Sales,
    COUNT(DISTINCT c.c_custkey) AS Unique_Customers
FROM 
    TopAvailableParts t1
JOIN 
    lineitem l ON l.l_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_name = t1.p_name LIMIT 1)
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
GROUP BY 
    t1.p_name, t1.p_mfgr, t1.p_brand, t1.p_type, t1.total_available, t1.avg_price
ORDER BY 
    Total_Sales DESC, Unique_Customers DESC;
