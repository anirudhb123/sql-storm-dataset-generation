WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) as PriceRank
    FROM orders o
    WHERE o.o_orderdate >= DATE '2022-01-01'
),
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS OrderCount,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    cu.c_name,
    cu.OrderCount,
    cu.TotalSpent,
    COALESCE(su.TotalSupplyCost, 0) AS SupplierCost,
    COUNT(DISTINCT lo.l_orderkey) AS DistinctLineItems,
    AVG(RankP.PriceRank) AS AveragePriorityRank
FROM CustomerOrders cu
LEFT JOIN lineitem lo ON cu.c_custkey = lo.l_orderkey
LEFT JOIN SupplierInfo su ON cu.TotalSpent > su.TotalSupplyCost
LEFT JOIN RankedOrders RankP ON RankP.o_orderkey = lo.l_orderkey
WHERE cu.TotalSpent IS NOT NULL
GROUP BY cu.c_name, cu.OrderCount, cu.TotalSpent
HAVING AVG(RankP.PriceRank) IS NOT NULL -- to filter out customers with no associated orders
ORDER BY cu.TotalSpent DESC
LIMIT 50;
