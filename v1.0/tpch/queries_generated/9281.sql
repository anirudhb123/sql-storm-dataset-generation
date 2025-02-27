WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
), HighVolumeOrders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_custkey
), CustomerRanks AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (ORDER BY hv.total_revenue DESC) AS revenue_rank
    FROM customer c
    JOIN HighVolumeOrders hv ON c.c_custkey = hv.o_custkey
), SupplierRankedWithCustomer AS (
    SELECT rs.s_suppkey, rs.s_name, cr.c_custkey, cr.c_name, cr.revenue_rank
    FROM RankedSuppliers rs
    JOIN CustomerRanks cr ON rs.rn <= 3
)
SELECT sr.s_suppkey, sr.s_name, 
       COUNT(distinct cr.c_custkey) AS top_customers_count
FROM SupplierRankedWithCustomer sr
LEFT JOIN customer c ON sr.c_custkey = c.c_custkey
GROUP BY sr.s_suppkey, sr.s_name
ORDER BY top_customers_count DESC
LIMIT 10;
