WITH SupplierPart AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_comment
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrder AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_nationkey, 
        o.o_orderkey, 
        o.o_orderstatus, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_comment
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
)
SELECT 
    r.r_name AS RegionName, 
    COUNT(DISTINCT sp.s_suppkey) AS SupplierCount, 
    COUNT(DISTINCT co.o_orderkey) AS OrderCount, 
    SUM(co.o_totalprice) AS TotalSales,
    STRING_AGG(DISTINCT sp.p_name, ', ') AS PartNames,
    STRING_AGG(DISTINCT sp.p_brand, ', ') AS UniqueBrands
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierPart sp ON s.s_suppkey = sp.s_suppkey
LEFT JOIN 
    CustomerOrder co ON n.n_nationkey = co.c_nationkey
WHERE 
    LENGTH(sp.p_comment) > 10 AND 
    co.o_orderstatus = 'O' AND 
    co.o_orderdate >= DATE '2023-01-01'
GROUP BY 
    r.r_name
ORDER BY 
    TotalSales DESC;
