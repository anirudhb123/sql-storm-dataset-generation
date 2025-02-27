WITH RECURSIVE SupplyChain AS (
    SELECT 
        ps_partkey,
        ps_suppkey,
        ps_availqty,
        ps_supplycost,
        0 AS Level
    FROM partsupp
    WHERE ps_availqty > 0
    UNION ALL
    SELECT 
        p.ps_partkey,
        p.ps_suppkey,
        p.ps_availqty,
        p.ps_supplycost,
        sc.Level + 1
    FROM partsupp p
    JOIN SupplyChain sc ON p.ps_partkey = sc.ps_partkey
    WHERE sc.Level < 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000
    GROUP BY c.c_custkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        AVG(l.l_extendedprice) AS AvgPrice,
        SUM(l.l_quantity) AS TotalQuantity,
        COUNT(DISTINCT l.l_suppkey) AS DistinctSuppliers
    FROM lineitem l
    GROUP BY l.l_orderkey
),
CombinedStats AS (
    SELECT 
        co.c_custkey,
        co.OrderCount,
        co.TotalSpent,
        ol.TotalQuantity,
        ts.TotalSupplyCost
    FROM CustomerOrders co
    JOIN OrderLineStats ol ON ol.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey
    )
    LEFT JOIN TopSuppliers ts ON co.TotalSpent > 2000
)
SELECT 
    cs.custkey,
    cs.OrderCount,
    cs.TotalSpent,
    cs.TotalQuantity,
    COALESCE(cs.TotalSupplyCost, 0) AS TotalSupplyCost,
    CASE 
        WHEN cs.OrderCount > 5 THEN 'Frequent'
        ELSE 'Occasional'
    END AS OrderFrequency,
    ROW_NUMBER() OVER (PARTITION BY cs.OrderFrequency ORDER BY cs.TotalSpent DESC) AS Rank
FROM (
    SELECT 
        c.c_custkey AS custkey,
        co.OrderCount,
        co.TotalSpent,
        ol.TotalQuantity,
        ts.TotalSupplyCost
    FROM CustomerOrders co
    JOIN OrderLineStats ol ON ol.l_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        WHERE o.o_custkey = co.c_custkey
    )
    LEFT JOIN TopSuppliers ts ON co.TotalSpent > 2000
) cs
WHERE cs.TotalSpent IS NOT NULL
ORDER BY cs.OrderFrequency, cs.TotalSpent DESC;
