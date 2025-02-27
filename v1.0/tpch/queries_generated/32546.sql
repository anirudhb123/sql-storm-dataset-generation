WITH RECURSIVE RegionCTE AS (
    SELECT r.r_regionkey, r.r_name, r.r_comment, 0 AS Depth
    FROM region r
    WHERE r.r_name LIKE 'N%'
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment, Depth + 1
    FROM region r
    JOIN RegionCTE rc ON r.r_regionkey = rc.r_regionkey
    WHERE Depth < 3
),
MaxOrders AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS OrderCount
    FROM orders o
    GROUP BY o.o_custkey
    HAVING COUNT(o.o_orderkey) = (
        SELECT MAX(OrderCount)
        FROM (
            SELECT COUNT(o1.o_orderkey) AS OrderCount
            FROM orders o1
            GROUP BY o1.o_custkey
        ) AS OrderCounts
    )
),
SupplierCost AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
QualifiedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS Rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)
SELECT DISTINCT p.p_partkey, p.p_name, r.r_name AS RegionName, 
       sc.TotalSupplyCost, qc.c_name AS TopCustomer, qc.c_acctbal
FROM part p
LEFT JOIN SupplierCost sc ON p.p_partkey = sc.ps_partkey
JOIN RegionCTE r ON r.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        JOIN supplier s ON n.n_nationkey = s.s_nationkey
        WHERE s.s_suppkey IN (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey
        ) LIMIT 1
    )
JOIN QualifiedCustomers qc ON qc.c_custkey IN (
        SELECT o.o_custkey
        FROM orders o
        WHERE o.o_orderkey IN (
            SELECT l.l_orderkey
            FROM lineitem l
            WHERE l.l_partkey = p.p_partkey
        )
    ) AND qc.Rank = 1
WHERE p.p_retailprice < (
    SELECT AVG(p2.p_retailprice) FROM part p2
    WHERE p2.p_size = p.p_size
)
OR p.p_comment IS NOT NULL
ORDER BY r.r_name, p.p_partkey;
