WITH RECURSIVE SupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS Level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, Level + 1
    FROM supplier s
    JOIN SupplierCTE sc ON s.s_suppkey = sc.s_suppkey
    WHERE sc.Level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS SupplierPart,
    coalesce(sum(ps.ps_availqty), 0) AS TotalAvailable,
    SUM(ol.TotalRevenue) AS TotalRevenueFromOrders,
    tc.TotalSpent,
    (SELECT COUNT(DISTINCT ll.l_orderkey) 
     FROM lineitem ll 
     WHERE ll.l_suppkey = s.s_suppkey AND ll.l_returnflag = 'R') AS ReturnCount
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN SupplierCTE s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN OrderSummary ol ON ol.o_orderkey = ps.ps_partkey
LEFT JOIN TopCustomers tc ON tc.c_custkey = ps.ps_partkey
GROUP BY s.s_supkey, p.p_name, tc.TotalSpent
HAVING SUM(ps.ps_availqty) IS NOT NULL
ORDER BY TotalRevenueFromOrders DESC, TotalAvailable ASC
FETCH FIRST 10 ROWS ONLY;
