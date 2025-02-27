WITH HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT 
    c.c_name AS CustomerName,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
    COALESCE(t.price_rank, 'No Rank') AS OrderRank,
    s.s_name AS SupplierName,
    h.TotalSupplyValue
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueSuppliers h ON l.l_suppkey = h.s_suppkey
LEFT JOIN TopOrders t ON o.o_orderkey = t.o_orderkey
LEFT JOIN supplier s ON s.s_suppkey = l.l_suppkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31' 
  AND (c.c_acctbal IS NOT NULL AND c.c_acctbal > 100)
GROUP BY c.c_name, t.price_rank, s.s_name, h.TotalSupplyValue
ORDER BY TotalSales DESC, CustomerName;
