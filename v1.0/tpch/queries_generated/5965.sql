WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT p.p_partkey) AS PartCount,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
CombinedStats AS (
    SELECT 
        ss.s_suppkey, 
        ss.s_name, 
        ss.TotalSupplyCost, 
        ss.PartCount,
        cs.c_custkey, 
        cs.c_name, 
        cs.OrderCount, 
        cs.TotalSpent
    FROM 
        SupplierStats ss
    LEFT JOIN 
        CustomerOrders cs ON ss.PartCount > 0
)
SELECT 
    cs.s_suppkey, 
    cs.s_name, 
    cs.TotalSupplyCost, 
    cs.PartCount, 
    cs.c_custkey, 
    cs.c_name, 
    cs.OrderCount, 
    cs.TotalSpent
FROM 
    CombinedStats cs
WHERE 
    cs.TotalSupplyCost > (SELECT AVG(TotalSupplyCost) FROM SupplierStats)
ORDER BY 
    cs.TotalSpent DESC, 
    cs.TotalSupplyCost DESC;
