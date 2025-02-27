WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalValue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSale
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(MONTH, -3, CURRENT_DATE)
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
CustomerRank AS (
    SELECT c.c_custkey, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(ro.TotalSale) DESC) AS RankInSegment
    FROM customer c
    JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT tr.RankInSegment, c.c_name, ts.TotalValue, 
       (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)) AS LineItemCount
FROM CustomerRank tr
JOIN customer c ON tr.c_custkey = c.c_custkey
JOIN TopSuppliers ts ON ts.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)))
ORDER BY tr.RankInSegment, ts.TotalValue DESC
LIMIT 10;
