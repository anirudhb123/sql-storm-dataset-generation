WITH SupplierRanked AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as Rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
PartStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS TotalAvailable,
        AVG(ps.ps_supplycost) AS AvgSupplyCost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerPurchase AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS TotalOrders,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    sr.s_name AS SupplierName,
    sr.Rank AS SupplierRank,
    ps.p_name AS PartName,
    ps.TotalAvailable AS AvailableQuantity,
    ps.AvgSupplyCost AS AverageCost,
    cp.c_name AS CustomerName,
    cp.TotalOrders AS OrdersCount,
    cp.TotalSpent AS TotalSpentAmount
FROM SupplierRanked sr
JOIN PartStats ps ON sr.s_suppkey = (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = ps.p_partkey ORDER BY ps_supplycost LIMIT 1)
JOIN CustomerPurchase cp ON cp.TotalSpent > 1000
WHERE sr.Rank <= 5 
ORDER BY SupplierRank, TotalSpent DESC;
