WITH RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS acctbal_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_seq
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT r.r_name AS region, 
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(co.o_totalprice) AS total_revenue,
       COALESCE(SUM(psi.total_supplycost), 0) AS total_supplycost,
       AVG(psi.total_supplycost) AS avg_supplycost_per_part
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN CustomerOrders co ON c.c_custkey = co.o_custkey
LEFT JOIN PartSupplierInfo psi ON psi.p_partkey IN 
    (SELECT l.l_partkey FROM lineitem l 
     WHERE l.l_orderkey = co.o_orderkey AND l.l_returnflag = 'R')
WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY total_revenue DESC;
