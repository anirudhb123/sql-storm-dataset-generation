WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    r.r_name AS RegionName,
    ns.n_name AS NationName,
    COUNT(DISTINCT cs.c_custkey) AS CustomerCount,
    AVG(cs.TotalSpent) AS AverageCustomerSpending,
    SUM(rsu.TotalSupplyCost) AS TotalSupplyCosts,
    MAX(rsu.TotalSupplyCost) OVER (PARTITION BY rsu.s_suppkey) AS MaxSupplyCost
FROM 
    RankedSuppliers rsu
JOIN 
    nation ns ON rsu.s_nationkey = ns.n_nationkey
JOIN 
    region r ON ns.n_regionkey = r.r_regionkey
LEFT JOIN 
    CustomerOrderSummary cs ON rsu.s_suppkey = cs.c_custkey
WHERE 
    ns.n_name IN ('Germany', 'USA', 'Japan')
GROUP BY 
    r.r_name, ns.n_name
ORDER BY 
    r.r_name, CustomerCount DESC;
