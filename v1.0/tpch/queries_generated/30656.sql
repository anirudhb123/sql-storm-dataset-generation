WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS Level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (
        SELECT n.n_nationkey
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0)
    )
    WHERE ch.Level < 5
),
TotalOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS OrderCount, SUM(o.o_totalprice) AS TotalSpend
    FROM orders o
    JOIN CustomerHierarchy ch ON o.o_custkey = ch.c_custkey
    GROUP BY o.o_custkey
),
RegionSummary AS (
    SELECT r.r_regionkey, r.r_name, SUM(TotalSpend) AS RegionTotalSpend
    FROM TotalOrders
    JOIN customer c ON TotalOrders.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY r.r_regionkey, r.r_name
)
SELECT r.r_name, COALESCE(rs.RegionTotalSpend, 0) AS TotalSpend,
       RANK() OVER (ORDER BY COALESCE(rs.RegionTotalSpend, 0) DESC) AS SpendRank
FROM region r
LEFT JOIN RegionSummary rs ON r.r_regionkey = rs.r_regionkey
WHERE r.r_name IS NOT NULL
ORDER BY SpendRank;
