WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY c.c_acctbal DESC) AS rn
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_orderdate
)
SELECT r.nation_name, r.s_name, r.s_acctbal, c.c_name, c.c_acctbal AS customer_acctbal,
       os.o_orderkey, os.total_revenue
FROM RankedSuppliers r
JOIN HighValueCustomers c ON r.nation_name = c.nation_name AND r.rn = 1
JOIN OrderStats os ON os.total_revenue > 10000
WHERE r.rn <= 5
ORDER BY r.nation_name, r.s_acctbal DESC, c.c_acctbal DESC;
