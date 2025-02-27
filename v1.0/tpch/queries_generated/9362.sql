WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name, 
           RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), 
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name AS region_name, 
           RANK() OVER (ORDER BY s.s_acctbal DESC) AS overall_rank
    FROM RankedSuppliers s
    JOIN region r ON (SELECT n.n_regionkey FROM nation n WHERE n.n_name = s.nation_name) = r.r_regionkey
    WHERE s.rank = 1
),
TotalOrderValues AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
),
CustomerWithTopOrders AS (
    SELECT c.c_custkey, c.c_name, o.total_value
    FROM customer c
    JOIN TotalOrderValues o ON c.c_custkey = o.o_custkey
    WHERE o.total_value > 10000
)
SELECT ts.s_name, ts.region_name, c.c_name, c.total_value
FROM TopSuppliers ts
JOIN CustomerWithTopOrders c ON c.total_value > 5000
ORDER BY ts.overall_rank, c.total_value DESC;
