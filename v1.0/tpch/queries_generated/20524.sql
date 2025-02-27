WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_availqty) > 1000
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sc.total_available + SUM(ps.ps_availqty)
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name, sc.total_available
    HAVING sc.total_available + SUM(ps.ps_availqty) > 2000
),
OrderStats AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank,
           COUNT(l.l_orderkey) AS item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus IN ('O', 'F')
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' OR o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
)
SELECT n.n_name, 
       COUNT(DISTINCT c.c_custkey) AS num_customers,
       AVG(o.o_totalprice) AS avg_order_value,
       MAX(o.o_orderdate) AS last_order_date,
       COALESCE(sc.total_available, 0) AS total_supply
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN SupplyChain sc ON sc.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps 
                                               WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p 
                                                                       WHERE p.p_retailprice < 50))
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > ALL (SELECT AVG(c1.c_acctbal) FROM customer c1)
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY num_customers DESC, last_order_date DESC
LIMIT 10;
