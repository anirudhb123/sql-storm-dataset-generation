WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        COUNT(DISTINCT ps.ps_partkey) AS TotalPartsSupplied,
        SUM(ps.ps_availqty) AS TotalAvailableQuantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent,
        MAX(o.o_orderdate) AS LastOrderDate
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartPopularity AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(DISTINCT l.l_orderkey) AS OrderCount,
        SUM(l.l_quantity) AS TotalQuantitySold
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
)
SELECT 
    ss.s_name AS SupplierName,
    cs.c_name AS CustomerName,
    pp.p_name AS PartName,
    ss.TotalPartsSupplied,
    ss.TotalAvailableQuantity,
    ss.TotalSupplyCost,
    cs.TotalOrders,
    cs.TotalSpent,
    cs.LastOrderDate,
    pp.OrderCount,
    pp.TotalQuantitySold
FROM 
    SupplierSummary ss
JOIN 
    CustomerOrderSummary cs ON ss.TotalPartsSupplied > 0
JOIN 
    PartPopularity pp ON pp.OrderCount > 0
ORDER BY 
    ss.TotalSupplyCost DESC, cs.TotalSpent DESC, pp.TotalQuantitySold DESC
LIMIT 10;
