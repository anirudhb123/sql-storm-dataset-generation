WITH RECURSIVE HighValueSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal, RANK() OVER (ORDER BY s_acctbal DESC) AS RankValue
    FROM supplier
    WHERE s_acctbal IS NOT NULL
),
OrdersWithDetails AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice,
           o.o_orderdate, 
           COALESCE(CAST(SUBSTRING_INDEX(s.s_name, ' ', -1) AS CHAR), 'Unknown') AS SupplierLastName,
           COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS LineCount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent,
           CASE WHEN SUM(o.o_totalprice) > 10000 THEN 'VIP' ELSE 'Regular' END AS CustomerType
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT DISTINCT
    COALESCE(c.c_name, 'No Customer') AS Customer,
    co.TotalSpent,
    ho.s_name AS HighValueSupplier,
    ho.RankValue AS SupplierRank,
    CASE WHEN co.CustomerType = 'VIP' THEN 'High Priority' ELSE 'Standard' END AS OrderPriority
FROM CustomerOrders co
FULL OUTER JOIN HighValueSuppliers ho ON co.TotalSpent > 5000
LEFT JOIN OrdersWithDetails od ON co.TotalSpent < od.o_totalprice AND od.SupplierLastName IS NOT NULL
WHERE ho.RankValue IS NULL OR od.LineCount > 1
ORDER BY co.TotalSpent DESC NULLS LAST;
