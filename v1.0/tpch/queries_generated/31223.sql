WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS Level
    FROM nation
    WHERE n_regionkey IS NOT NULL

    UNION ALL

    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.Level + 1
    FROM nation n
    JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
SupplierStats AS (
    SELECT s.s_nationkey, COUNT(ps.ps_suppkey) AS TotalSuppliers,
           SUM(s.s_acctbal) AS TotalBalance,
           AVG(s.s_acctbal) AS AvgBalance
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_nationkey
),
PartStats AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_quantity) AS TotalQuantity,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales,
           COUNT(DISTINCT ps.ps_suppkey) AS SupplierCount
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS PriceRank,
           SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS ReturnedQuantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
)
SELECT n.n_name AS NationName, ps.TotalBalance, ps.TotalSuppliers, 
       p.p_name AS PartName, p.SupplierCount, 
       o.o_orderkey, o.o_totalprice, o.ReturnedQuantity
FROM NationHierarchy n
JOIN SupplierStats ps ON n.n_nationkey = ps.s_nationkey
JOIN PartStats p ON p.SupplierCount > 0
LEFT JOIN OrderSummary o ON o.PriceRank <= 10
WHERE ps.TotalBalance IS NOT NULL AND ps.TotalSuppliers > 0
ORDER BY n.n_name, ps.TotalBalance DESC, o.o_totalprice DESC;
