WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_nationkey, c_acctbal, 0 AS Level
    FROM customer
    WHERE c_acctbal > 1000
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, Level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = cc.c_nationkey
    WHERE LEVEL < 5 AND c.c_acctbal > 1000
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 20)
    GROUP BY p.p_partkey, p.p_name
),
MaxSupplierCount AS (
    SELECT MAX(SupplierCount) AS MaxCount
    FROM FilteredParts
    WHERE SupplierCount IS NOT NULL
),
MatchingOrders AS (
    SELECT DISTINCT o.o_orderkey, o.o_totalprice, o.o_orderdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount BETWEEN 0.05 AND 0.15
    AND EXISTS (
        SELECT 1
        FROM CustomerCTE cc
        WHERE cc.c_custkey = o.o_custkey
    )
    AND o.o_orderdate = (
        SELECT MAX(o2.o_orderdate)
        FROM orders o2
        WHERE o2.o_custkey = o.o_custkey AND o2.o_orderstatus = 'F'
    )
)
SELECT 
    p.p_name,
    COALESCE(MAX(SupplierCount), 0) AS TotalSuppliers,
    COUNT(DISTINCT mo.o_orderkey) AS TotalOrders,
    SUM(mo.o_totalprice) AS TotalRevenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(mo.o_totalprice) DESC) AS Rank
FROM FilteredParts p
LEFT JOIN MatchingOrders mo ON p.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_quantity < 20
    UNION
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_returnflag = 'R'
)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT mo.o_orderkey) >= (SELECT COALESCE(MIN(MinCount), 1) FROM (
    SELECT COUNT(DISTINCT o.o_orderkey) AS MinCount 
    FROM orders o 
    WHERE o.o_orderstatus <> 'F'
    GROUP BY o.o_custkey
) AS Counts)
ORDER BY TotalRevenue DESC, Rank
LIMIT 10;
