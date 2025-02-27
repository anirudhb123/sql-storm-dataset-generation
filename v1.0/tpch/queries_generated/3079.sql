WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        COUNT(DISTINCT ps.ps_partkey) AS PartCount
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
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
), 
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(o.OrderCount, 0) AS Orders,
        COALESCE(o.TotalSpent, 0) AS Spent,
        CASE 
            WHEN c.c_acctbal >= 1000 THEN 'High Value'
            ELSE 'Regular'
        END AS CustomerType
    FROM 
        customer c
    LEFT JOIN 
        CustomerOrders o ON c.c_custkey = o.c_custkey
)
SELECT 
    r.r_name AS Region, 
    SUM(ss.TotalSupplyCost) AS TotalSupplierCost,
    COUNT(DISTINCT hvc.c_custkey) AS HighValueClientCount,
    AVG(hvc.Spent) AS AvgHighValueSpent
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN 
    HighValueCustomers hvc ON hvc.c_name LIKE CONCAT('%', SUBSTRING(ss.s_name, 1, 3), '%')
GROUP BY 
    r.r_name
HAVING 
    AVG(hvc.Spent) IS NOT NULL
ORDER BY 
    TotalSupplierCost DESC, Region;
