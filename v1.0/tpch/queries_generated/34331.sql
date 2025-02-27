WITH RECURSIVE CustomerCTE AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, 1 AS Level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c1.c_acctbal) FROM customer c1)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_nationkey, c.c_acctbal, cc.Level + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = cc.c_nationkey
    WHERE cc.Level < 3
),
OrderSummary AS (
    SELECT o.o_custkey, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalSpent
    FROM orders o
    GROUP BY o.o_custkey
),
SupplierPart AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS TotalAvailable
    FROM partsupp ps
    GROUP BY ps.ps_partkey
    HAVING SUM(ps.ps_availqty) > 100
)
SELECT 
    c.c_name, 
    c.c_acctbal,
    COALESCE(os.TotalOrders, 0) AS TotalOrders,
    COALESCE(os.TotalSpent, 0) AS TotalSpent,
    sp.TotalAvailable,
    RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS NationalRank
FROM CustomerCTE c
LEFT JOIN OrderSummary os ON c.c_custkey = os.o_custkey
LEFT JOIN supplier s ON c.c_nationkey = s.s_nationkey
LEFT JOIN SupplierPart sp ON sp.ps_partkey = (SELECT p.p_partkey FROM part p WHERE p.p_brand = s.s_name LIMIT 1)
WHERE c.c_acctbal IS NOT NULL
  AND c.c_name LIKE 'A%'
ORDER BY c.c_nationkey, c.c_name;
