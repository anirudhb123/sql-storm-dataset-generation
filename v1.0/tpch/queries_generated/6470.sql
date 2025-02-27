WITH SupplierParts AS (
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
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > (
            SELECT 
                AVG(s2.s_acctbal)
            FROM 
                supplier s2
        )
),
CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name AS Region,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    SUM(COALESCE(os.TotalSpent, 0)) AS TotalSpentByCustomers,
    SUM(sp.TotalSupplyCost) AS TotalSupplyCostByTopSuppliers
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    SupplierParts sp ON s.s_suppkey = sp.s_suppkey
JOIN 
    CustomerOrderSummary os ON os.c_custkey IN (
        SELECT 
            c.c_custkey 
        FROM 
            customer c
        JOIN 
            TopSuppliers ts ON c.c_nationkey = ts.s_suppkey
    )
GROUP BY 
    r.r_name
ORDER BY 
    UniqueCustomers DESC, TotalSpentByCustomers DESC;
