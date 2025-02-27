WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS TotalCost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty * ps.ps_supplycost) DESC) AS RankByCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS LatestOrder
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
)
SELECT r.r_name, 
       COALESCE(SUM(CASE WHEN lo.l_returnflag = 'R' THEN lo.l_extendedprice ELSE 0 END), 0) AS TotalRefunds,
       COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount) * (1 + lo.l_tax)), 0) AS TotalNetSales,
       COUNT(DISTINCT co.c_custkey) AS UniqueCustomers,
       COUNT(DISTINCT rs.s_suppkey) AS ActiveSuppliers
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem lo ON ps.ps_partkey = lo.l_partkey
LEFT JOIN CustomerOrders co ON co.o_orderdate >= '2023-01-01' AND lo.l_orderkey = co.o_orderkey
LEFT JOIN RankedSuppliers rs ON s.s_nationkey = rs.s_suppkey
WHERE r.r_name ILIKE '%East%'
GROUP BY r.r_name
HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 10000
ORDER BY TotalNetSales DESC;
