WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           ROW_NUMBER() OVER(PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, r.r_name AS region_name
    FROM RankedSuppliers s
    JOIN nation n ON s.nation_name = n.n_name
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE s.rank <= 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, c.total_spent
    FROM CustomerOrders c
    WHERE c.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
),
FinalReport AS (
    SELECT t.nation_name, t.region_name, c.c_name, c.total_spent, s.s_name, s.s_acctbal
    FROM TopCustomers c
    JOIN TopSuppliers s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)))
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT nation_name, region_name, c_name, total_spent, s_name, s_acctbal
FROM FinalReport
ORDER BY total_spent DESC, s_acctbal DESC;
