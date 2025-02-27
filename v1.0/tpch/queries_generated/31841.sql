WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) as rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, c.c_mktsegment, c.c_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rnk
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderdate, c.c_mktsegment, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o_totalprice) FROM orders)
),
FinalReport AS (
    SELECT sc.s_name, sc.p_name, sc.ps_availqty, sc.ps_supplycost,
           COALESCE(hvc.total_spent, 0) AS total_customer_spent,
           COUNT(DISTINCT ro.o_orderkey) AS orders_count
    FROM SupplyChain sc
    LEFT JOIN RankedOrders ro ON sc.p_partkey = ro.o_orderkey
    LEFT JOIN HighValueCustomers hvc ON ro.o_custkey = hvc.c_custkey
    WHERE sc.rn = 1
    GROUP BY sc.s_name, sc.p_name, sc.ps_availqty, sc.ps_supplycost, hvc.total_spent
)
SELECT * 
FROM FinalReport 
WHERE total_customer_spent IS NOT NULL 
ORDER BY total_customer_spent DESC, ps_supplycost ASC
LIMIT 10;
