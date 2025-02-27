WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS RankCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey
),
TopSuppliers AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name,
        ts.TotalSupplyCost
    FROM RankedSuppliers ts
    WHERE ts.RankCost <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS TotalLineItems
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice
),
OrderSummary AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        SUM(co.o_totalprice) AS TotalSpent,
        COUNT(co.o_orderkey) AS OrderCount
    FROM CustomerOrders co
    GROUP BY co.c_custkey, co.c_name
)
SELECT 
    os.c_custkey,
    os.c_name,
    os.TotalSpent,
    os.OrderCount,
    ts.s_name AS TopSupplier,
    ts.TotalSupplyCost
FROM OrderSummary os
JOIN TopSuppliers ts ON os.TotalSpent > ts.TotalSupplyCost
WHERE os.OrderCount > 5
ORDER BY os.TotalSpent DESC, ts.TotalSupplyCost ASC;
