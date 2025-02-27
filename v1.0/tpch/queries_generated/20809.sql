WITH RankedOrders AS (
    SELECT o.o_orderkey,
           o.o_orderstatus,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderpriority,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    WHERE o.o_orderdate < CURRENT_DATE AND o.o_orderstatus IN ('O', 'F')
),
HighValueSuppliers AS (
    SELECT ps.ps_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 50000
),
CustomerWithOrders AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) >= 0
)
SELECT COALESCE(c.c_name, 'Unknown Customer') AS CustomerName,
       c.OrderCount,
       ro.o_orderkey,
       ro.o_totalprice,
       ro.o_orderdate,
       CASE 
           WHEN HVS.TotalSupplyValue IS NOT NULL THEN 'High Value Supplier'
           ELSE 'Other Supplier'
       END AS SupplierCategory,
       DENSE_RANK() OVER (PARTITION BY c.c_name ORDER BY ro.o_totalprice DESC) AS PriceRank
FROM CustomerWithOrders c
FULL OUTER JOIN RankedOrders ro ON c.OrderCount > 0
LEFT JOIN HighValueSuppliers HVS ON HVS.ps_suppkey = ro.o_orderkey  -- In a bizarre twist, leveraging orderkey for supplier key
WHERE ro.o_orderstatus IS NOT NULL
  AND c.c_custkey IS NOT NULL
  AND (c.OrderCount IS NULL OR c.OrderCount > 1 OR HVS.TotalSupplyValue IS NOT NULL)
ORDER BY SupplierCategory, CustomerName, ro.o_totalprice DESC;
