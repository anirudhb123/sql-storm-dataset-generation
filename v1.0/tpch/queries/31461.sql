WITH RECURSIVE SupplyChain AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        0 AS Level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        sc.Level + 1
    FROM 
        supplier s
    JOIN 
        SupplyChain sc ON s.s_suppkey = sc.s_suppkey
    WHERE 
        s.s_acctbal > sc.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS OrderRank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
PartSuppliers AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
FilteredSupply AS (
    SELECT 
        sc.s_name, 
        sc.s_acctbal, 
        cs.c_name, 
        cs.OrderCount, 
        cs.TotalSpent
    FROM 
        SupplyChain sc
    FULL OUTER JOIN CustomerOrders cs ON sc.s_suppkey = cs.c_custkey
),
FinalReport AS (
    SELECT 
        f.s_name,
        f.s_acctbal,
        f.c_name,
        COALESCE(f.OrderCount, 0) AS OrderCount,
        COALESCE(f.TotalSpent, 0) AS TotalSpent,
        ps.TotalSupplyCost
    FROM 
        FilteredSupply f
    LEFT JOIN 
        PartSuppliers ps ON f.s_name LIKE '%' || ps.p_name || '%'
)
SELECT 
    f.s_name,
    f.c_name,
    f.OrderCount,
    f.TotalSpent,
    f.TotalSupplyCost,
    CASE 
        WHEN f.TotalSpent > 50000 THEN 'High Value Customer' 
        ELSE 'Regular Customer' 
    END AS CustomerType
FROM 
    FinalReport f
WHERE 
    f.TotalSupplyCost IS NOT NULL
AND 
    f.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier)
ORDER BY 
    f.TotalSupplyCost DESC, 
    f.OrderCount DESC;
