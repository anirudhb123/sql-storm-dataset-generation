WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalCost,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied,
        AVG(ps.ps_supplycost) AS AverageSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
OrderLineStatistics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue,
        SUM(l.l_quantity) AS TotalQuantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)

SELECT 
    sp.s_name AS SupplierName,
    sp.TotalCost AS SupplierTotalCost,
    sp.UniquePartsSupplied AS SupplierUniqueParts,
    co.c_name AS CustomerName,
    co.TotalOrders AS CustomerTotalOrders,
    co.TotalSpent AS CustomerTotalSpent,
    ol.NetRevenue AS OrderNetRevenue,
    ol.TotalQuantity AS OrderTotalQuantity
FROM 
    SupplierPerformance sp
JOIN 
    CustomerOrders co ON sp.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY RANDOM() LIMIT 1)
JOIN 
    OrderLineStatistics ol ON ol.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY RANDOM() LIMIT 1)
WHERE 
    sp.TotalCost > 50000
ORDER BY 
    sp.TotalCost DESC, co.TotalSpent DESC
LIMIT 100;
