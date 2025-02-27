WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS Depth
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal) FROM supplier s2
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, Depth + 1
    FROM supplier s
    INNER JOIN SupplierCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal > cte.s_acctbal
), 
NationStats AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS SupplierCount,
           SUM(s.s_acctbal) AS TotalAccountBalance,
           RANK() OVER (ORDER BY SUM(s.s_acctbal) DESC) AS BalanceRank
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS OrderCount,
           SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
FilteredLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_quantity,
           l.l_extendedprice, l.l_discount,
           CASE WHEN l.l_discount = 0 THEN 'No Discount' ELSE 'Discounted' END AS DiscountStatus
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
),
FinalResults AS (
    SELECT n.n_name, n.SupplierCount, n.TotalAccountBalance,
           co.c_name, co.OrderCount, co.TotalSpent,
           li.DiscountStatus,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY n.TotalAccountBalance DESC) AS RegionRank
    FROM NationStats n
    LEFT JOIN CustomerOrders co ON n.SupplierCount = co.OrderCount
    LEFT JOIN FilteredLineItems li ON li.l_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        WHERE o.o_orderstatus = 'O'
    )
)
SELECT f.n_name, f.c_name, f.OrderCount, f.TotalSpent, f.DiscountStatus,
       CASE WHEN f.TotalSpent IS NULL THEN 'No Orders' ELSE 'Orders Placed' END AS OrderStatus,
       f.RegionRank
FROM FinalResults f
WHERE f.RegionRank <= 3 
ORDER BY f.n_name, f.TotalSpent DESC;
