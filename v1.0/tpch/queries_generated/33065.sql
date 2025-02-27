WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey,
           o_custkey,
           o_orderstatus,
           o_totalprice,
           o_orderdate,
           o_orderpriority,
           o_clerk,
           o_shippriority,
           1 AS OrderLevel
    FROM orders
    WHERE o_orderdate >= DATE '2023-01-01'

    UNION ALL

    SELECT o.o_orderkey,
           o.o_custkey,
           o.o_orderstatus,
           o.o_totalprice,
           o.o_orderdate,
           o.o_orderpriority,
           o.o_clerk,
           o.o_shippriority,
           oh.OrderLevel + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey AND o.o_orderdate > oh.o_orderdate
    WHERE o.o_orderstatus = 'O'
), PriceAggregation AS (
    SELECT p.p_partkey,
           p.p_name,
           SUM(ls.l_extendedprice * (1 - ls.l_discount)) AS TotalSales,
           COUNT(DISTINCT ls.l_orderkey) AS OrderCount
    FROM part p
    JOIN lineitem ls ON p.p_partkey = ls.l_partkey
    GROUP BY p.p_partkey, p.p_name
), SupplierInfo AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS SupplierRevenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
), FinalResults AS (
    SELECT oh.o_orderkey,
           oh.o_custkey,
           oh.o_orderstatus,
           oh.o_totalprice,
           pa.p_name,
           pa.TotalSales,
           si.SupplierRevenue,
           ROW_NUMBER() OVER (PARTITION BY oh.o_custkey ORDER BY oh.o_totalprice DESC) AS Rank
    FROM OrderHierarchy oh
    LEFT JOIN PriceAggregation pa ON oh.o_orderkey IN (SELECT l_orderkey FROM lineitem)
    LEFT JOIN SupplierInfo si ON EXISTS (SELECT 1 FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p_partkey FROM part))
)
SELECT fr.o_orderkey,
       fr.o_custkey,
       fr.o_orderstatus,
       fr.o_totalprice,
       fr.p_name,
       COALESCE(fr.TotalSales, 0) AS TotalSales,
       COALESCE(fr.SupplierRevenue, 0) AS SupplierRevenue,
       fr.Rank
FROM FinalResults fr
WHERE fr.TotalSales > (SELECT AVG(TotalSales) FROM PriceAggregation)
  AND fr.SupplierRevenue IS NOT NULL
ORDER BY fr.o_orderkey;
