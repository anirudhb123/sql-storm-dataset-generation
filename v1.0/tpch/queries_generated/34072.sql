WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, ps_suppkey, ps_availqty, ps_supplycost, 1 AS level
    FROM partsupp
    UNION ALL
    SELECT p.ps_partkey, p.ps_suppkey, p.ps_availqty, p.ps_supplycost * 0.9 AS ps_supplycost, level + 1
    FROM partsupp p
    JOIN SupplyCostCTE s ON p.ps_partkey = s.ps_partkey AND p.ps_suppkey = s.ps_suppkey
    WHERE level < 5
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS PriceRank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
),
FilteredCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY c.c_acctbal DESC) AS SegmentRank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
)
SELECT 
    n.n_name AS Nation,
    r.r_name AS Region,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    AVG(s.ps_supplycost) AS AvgSupplyCost,
    COALESCE(fc.c_name, 'No Top Customers') AS TopCustomerName
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN FilteredCustomers fc ON c.c_custkey = fc.c_custkey
WHERE l.l_shipdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
GROUP BY ROLLUP(n.n_name, r.r_name, fc.c_name)
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY TotalRevenue DESC, Nation, Region;
