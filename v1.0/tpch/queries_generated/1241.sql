WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighSpendingCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        co.TotalSpent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.TotalSpent > (SELECT AVG(TotalSpent) FROM CustomerOrders)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sp.TotalSupplyCost,
        ROW_NUMBER() OVER (ORDER BY sp.TotalSupplyCost DESC) AS rn
    FROM 
        SupplierParts sp
    JOIN 
        supplier s ON sp.s_suppkey = s.s_suppkey
)
SELECT 
    hsc.c_custkey,
    hsc.c_name,
    hsc.TotalSpent,
    ts.s_suppkey,
    ts.s_name,
    ts.TotalSupplyCost,
    COALESCE(hsc.TotalSpent - ts.TotalSupplyCost, hsc.TotalSpent) AS RemainingBalance
FROM 
    HighSpendingCustomers hsc
FULL OUTER JOIN 
    TopSuppliers ts ON hsc.c_custkey % 10 = ts.s_suppkey % 10
WHERE 
    hsc.c_custkey IS NOT NULL OR ts.s_suppkey IS NOT NULL
ORDER BY 
    hsc.TotalSpent DESC NULLS LAST, 
    ts.TotalSupplyCost DESC NULLS LAST;
