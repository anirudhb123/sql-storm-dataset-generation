WITH RECURSIVE nation_parts AS (
    SELECT n.n_nationkey, n.n_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_nationkey, n.n_name
),
ranked_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL AND p.p_size > 0
),
frequent_orders AS (
    SELECT o.o_clerk, COUNT(o.o_orderkey) AS orders_count
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -12, GETDATE())
    GROUP BY o.o_clerk
    HAVING COUNT(o.o_orderkey) > 5
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal = (SELECT MAX(c1.c_acctbal)
                         FROM customer c1
                         WHERE c1.c_mktsegment='BUILDINGS') 
    OR c.c_acctbal = (SELECT MIN(c2.c_acctbal)
                      FROM customer c2
                      WHERE c2.c_mktsegment='FOOD')
)
SELECT np.n_name, 
       rp.p_name,
       COALESCE(SUM(np.total_avail_qty * rp.p_retailprice), 0) AS revenue_generated, 
       ho.orders_count,
       CASE 
           WHEN ho.orders_count IS NOT NULL THEN 'Frequent Customer'
           ELSE 'Sporadic Customer' 
       END AS customer_type
FROM nation_parts np
LEFT JOIN ranked_parts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
LEFT JOIN frequent_orders ho ON ho.o_clerk = (SELECT TOP 1 o.o_clerk FROM orders o WHERE o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_returnflag = 'R') ORDER BY o.o_orderdate DESC)
LEFT JOIN high_value_customers hvc ON hvc.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_totalprice > 1000)
GROUP BY np.n_name, rp.p_name, ho.orders_count
HAVING COALESCE(SUM(np.total_avail_qty * rp.p_retailprice), 0) > 5000 OR EXISTS (SELECT 1 FROM high_value_customers WHERE hvc.c_acctbal > 500)
ORDER BY revenue_generated DESC, np.n_name
OPTION (MAXRECURSION 100)
