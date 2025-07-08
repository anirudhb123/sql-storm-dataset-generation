
WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, 
           ps.ps_availqty, ps.ps_supplycost, 0 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_partkey, 
           ps.ps_availqty, ps.ps_supplycost, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplyChain sc ON sc.ps_partkey = ps.ps_partkey
    WHERE sc.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
RankedOrders AS (
    SELECT o.o_orderkey, c.c_name, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
)
SELECT p.p_name, r.r_name, COUNT(DISTINCT sc.s_suppkey) AS num_suppliers,
       AVG(sc.ps_supplycost) AS avg_supplycost, COALESCE(SUM(co.total_spent), 0) AS total_customer_spent,
       MAX(ho.o_orderdate) AS last_order_date, COUNT(ho.o_orderkey) AS order_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplyChain sc ON ps.ps_partkey = sc.ps_partkey
LEFT JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = (SELECT MAX(o.o_custkey) FROM orders o)))
LEFT JOIN CustomerOrders co ON co.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MAX(o2.o_orderkey) FROM orders o2 WHERE o2.o_orderdate < DATE '1998-10-01'))
LEFT JOIN RankedOrders ho ON ho.o_orderkey = co.c_custkey
WHERE p.p_retailprice > 50.00
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT sc.s_suppkey) > 0 AND AVG(sc.ps_supplycost) < 200.00
ORDER BY p.p_name ASC, total_customer_spent DESC;
