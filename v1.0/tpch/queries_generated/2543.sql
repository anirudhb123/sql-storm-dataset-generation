WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus IS NULL
    GROUP BY c.c_custkey
)
SELECT 
    c.c_name,
    c.c_acctbal,
    o.OrderCount,
    o.TotalSpent,
    CASE 
        WHEN o.TotalSpent IS NULL THEN 'No Orders'
        WHEN o.TotalSpent < 1000 THEN 'Low Spender'
        ELSE 'High Roller' 
    END AS SpendingCategory,
    COALESCE(s.s_name, 'No Supplier') AS TopSupplier
FROM customer c
JOIN CustomerOrders o ON c.c_custkey = o.c_custkey
LEFT JOIN RankedSuppliers s ON s.SupplierRank = 1
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
ORDER BY c.c_acctbal DESC, o.TotalSpent DESC
LIMIT 100;
