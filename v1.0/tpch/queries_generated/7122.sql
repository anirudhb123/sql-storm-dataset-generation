WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost,
           ROW_NUMBER() OVER (ORDER BY ps.ps_supplycost DESC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-12-31'
    GROUP BY o.o_orderkey
),
CustomerPurchases AS (
    SELECT c.c_custkey, c.c_name, SUM(od.total_revenue) AS total_spent
    FROM customer c
    JOIN OrderDetails od ON c.c_custkey = od.o_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name AS region, COUNT(DISTINCT c.c_custkey) AS cust_count,
       SUM(cp.total_spent) AS total_spent,
       AVG(cp.total_spent) AS avg_spent,
       MAX(sa.s_acctbal) AS max_supplier_acctbal
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier sa ON n.n_nationkey = sa.s_nationkey
LEFT JOIN CustomerPurchases cp ON sa.s_suppkey = cp.c_custkey
WHERE sa.rn <= 5 AND cp.total_spent IS NOT NULL
GROUP BY r.r_name
ORDER BY total_spent DESC;
