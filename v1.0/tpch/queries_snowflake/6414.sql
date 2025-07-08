WITH RevenueBySupplier AS (
    SELECT 
        s.s_name AS SupplierName,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        s.s_name
), 
TopSuppliers AS (
    SELECT 
        SupplierName,
        TotalRevenue,
        ROW_NUMBER() OVER (ORDER BY TotalRevenue DESC) AS Rank
    FROM 
        RevenueBySupplier
)
SELECT 
    ts.SupplierName,
    ts.TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS NumberOfOrders,
    AVG(o.o_totalprice) AS AverageOrderValue,
    MIN(o.o_orderdate) AS FirstOrderDate,
    MAX(o.o_orderdate) AS LastOrderDate
FROM 
    TopSuppliers ts
JOIN 
    partsupp ps ON ts.SupplierName = (SELECT s.s_name FROM supplier s WHERE s.s_suppkey = ps.ps_suppkey)
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    ts.Rank <= 10
GROUP BY 
    ts.SupplierName, ts.TotalRevenue
ORDER BY 
    ts.TotalRevenue DESC;
