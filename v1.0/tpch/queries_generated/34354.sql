WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 0 AS Level
    FROM supplier
    WHERE s_acctbal > 10000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as OrderRank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
SupplierPartDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS TotalAvailQty, avg(ps.ps_supplycost) AS AvgSupplyCost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
FilteredOrders AS (
    SELECT co.*, sp.p_name, sp.TotalAvailQty, sp.AvgSupplyCost,
           CASE 
               WHEN co.o_totalprice > 1000 THEN 'High Value'
               WHEN co.o_totalprice BETWEEN 500 AND 1000 THEN 'Medium Value'
               ELSE 'Low Value'
           END as PriceCategory
    FROM CustomerOrders co
    LEFT JOIN SupplierPartDetails sp ON co.o_orderkey = sp.p_partkey
    WHERE co.OrderRank <= 5
)
SELECT rh.r_name, COUNT(DISTINCT fo.o_orderkey) AS UniqueOrders,
       AVG(fo.o_totalprice) AS AvgTotalPrice, MAX(fo.AvgSupplyCost) AS MaxAverageSupplyCost,
       SUM(CASE WHEN fo.PriceCategory = 'High Value' THEN 1 ELSE 0 END) AS HighValueCount
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN FilteredOrders fo ON s.s_suppkey = fo.o_orderkey
WHERE s.s_acctbal IS NOT NULL AND fo.o_orderdate > '2023-01-01'
GROUP BY rh.r_name
ORDER BY UniqueOrders DESC, AvgTotalPrice DESC;
