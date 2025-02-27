WITH RECURSIVE RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS Rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    c.c_custkey,
    c.c_name,
    co.TotalOrders,
    co.TotalSpent,
    CASE 
        WHEN co.TotalSpent IS NULL THEN 'No Orders' 
        WHEN co.TotalSpent < 500 THEN 'Low Spender'
        WHEN co.TotalSpent BETWEEN 500 AND 1500 THEN 'Medium Spender'
        ELSE 'High Spender' 
    END AS SpendingCategory,
    rs.s_name AS TopSupplier,
    rs.TotalCost AS SupplierCost
FROM 
    CustomerOrders co
JOIN 
    customer c ON co.c_custkey = c.c_custkey
LEFT JOIN 
    RankedSuppliers rs ON rs.Rank = 1 AND rs.s_nationkey = c.c_nationkey
WHERE 
    co.TotalOrders > 0 
    AND (co.TotalSpent IS NOT NULL OR c.c_acctbal > 1000)
ORDER BY 
    co.TotalSpent DESC;
