
WITH RegionalSales AS (
    SELECT 
        n.n_name AS Nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
SupplierInventory AS (
    SELECT 
        s.s_name AS SupplierName,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount,
        SUM(ps.ps_availqty) AS TotalAvailable
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_name
),
TopNations AS (
    SELECT 
        Nation,
        ROW_NUMBER() OVER (ORDER BY TotalSales DESC) AS SalesRank
    FROM 
        RegionalSales
    WHERE 
        TotalSales IS NOT NULL
),
SupplierSales AS (
    SELECT 
        s.s_name AS Supplier,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS SupplierSales
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_name
)
SELECT 
    t.Nation,
    t.SalesRank,
    si.SupplierName,
    si.PartCount,
    si.TotalAvailable,
    COALESCE(s.SupplierSales, 0) AS SupplierSales,
    COALESCE(s.SupplierSales, 0) - COALESCE(si.TotalAvailable, 0) AS SalesMinusAvailability
FROM 
    TopNations t
LEFT JOIN 
    SupplierInventory si ON t.SalesRank = (SELECT COUNT(*) FROM TopNations x WHERE x.SalesRank < t.SalesRank) + 1
LEFT JOIN 
    SupplierSales s ON si.SupplierName = s.Supplier
WHERE 
    (s.SupplierSales IS NULL OR s.SupplierSales > 5000)
ORDER BY 
    t.SalesRank, si.PartCount DESC;
