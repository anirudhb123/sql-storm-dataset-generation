WITH CTE_SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Cost,
        COUNT(DISTINCT ps.ps_partkey) AS Part_Count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CTE_BestSellingParts AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_quantity) AS Total_Sold,
        RANK() OVER (ORDER BY SUM(l.l_quantity) DESC) AS Part_Rank
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        l.l_partkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    sp.Total_Cost,
    bs.Total_Sold,
    CASE 
        WHEN sp.Part_Count > 1 THEN 'Multiple' 
        ELSE 'Single' 
    END AS Supplier_Category
FROM 
    part p
LEFT JOIN 
    CTE_SupplierPerformance sp ON p.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = sp.s_suppkey)
LEFT JOIN 
    CTE_BestSellingParts bs ON p.p_partkey = bs.l_partkey
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND p.p_size IN (SELECT DISTINCT p3.p_size FROM part p3 WHERE p3.p_retailprice > 50)
ORDER BY 
    sp.Total_Cost DESC NULLS LAST, 
    bs.Total_Sold DESC NULLS LAST;
