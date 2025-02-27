
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS PriceRank
    FROM part p
), 
SupplierAvailability AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           ps.ps_availqty, 
           SUM(ps.ps_supplycost) AS TotalSupplyCost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
), 
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           CASE 
               WHEN c.c_acctbal < 0 THEN 'Bankrupt Customer'
               WHEN c.c_acctbal BETWEEN 0 AND 1000 THEN 'Low Value'
               ELSE 'High Value'
           END AS CustomerValue
    FROM customer c
), 
OrderAnalysis AS (
    SELECT o.o_orderkey, 
           o.o_totalprice, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue, 
           COUNT(DISTINCT l.l_partkey) AS UniqueParts
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT 
    r.NationName, 
    SUM(oa.NetRevenue) AS TotalRevenue,
    AVG(oa.UniqueParts) AS AvgUniqueParts,
    COALESCE(MAX(p.PriceRank), 0) AS MaxPartPriceRank,
    CASE 
        WHEN SUM(oa.NetRevenue) IS NULL THEN 'No Revenue'
        ELSE 'Revenue Exists'
    END AS RevenueStatus
FROM (
    SELECT n.n_nationkey, 
           n.n_name AS NationName
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
) r
LEFT JOIN OrderAnalysis oa ON r.NationName = CAST(oa.o_orderkey AS VARCHAR)
LEFT JOIN RankedParts p ON p.p_partkey = oa.UniqueParts
GROUP BY r.NationName
HAVING COUNT(DISTINCT oa.o_orderkey) > 1
ORDER BY TotalRevenue DESC, AvgUniqueParts ASC;
