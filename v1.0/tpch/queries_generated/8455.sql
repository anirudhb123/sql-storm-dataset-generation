WITH HighValueProducts AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice
    FROM part
    WHERE p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2022-01-01' AND o.o_orderdate <= DATE '2022-12-31'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, SUM(od.total_revenue) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT n.n_name, n.total_revenue, s.s_name, s.total_available, s.total_cost, hp.p_name, hp.p_brand
FROM NationRevenue n
JOIN SupplierStats s ON n.n_nationkey = s.s_nationkey
JOIN HighValueProducts hp ON hp.p_partkey = ANY (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
ORDER BY n.total_revenue DESC, s.total_available ASC;
