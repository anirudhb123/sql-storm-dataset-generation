WITH RECURSIVE SupplierTree AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, p.p_partkey, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps2.ps_supplycost) 
                               FROM partsupp ps2 
                               WHERE ps2.ps_partkey = p.p_partkey)
),
DistinctRegions AS (
    SELECT DISTINCT r.r_regionkey, r.r_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    WHERE n.n_name LIKE 'A%'
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
CustomerPerformance AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING total_spent > 1000 AND COUNT(o.o_orderkey) > 5
)
SELECT DISTINCT 
    st.s_nationkey,
    r.r_name,
    SUM(cs.total_spent) AS total_customers_cost,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    (SELECT COUNT(DISTINCT o.o_orderkey)
     FROM orders o
     WHERE o.o_orderstatus = 'O' 
       AND EXISTS (SELECT 1 
                   FROM lineitem l 
                   WHERE l.l_orderkey = o.o_orderkey 
                     AND l.l_discount > 0.1)) AS outstanding_orders,
    SUM(CASE WHEN cs.avg_order_value IS NULL THEN 0 ELSE cs.avg_order_value END) AS total_average_order_value
FROM SupplierTree st
JOIN DistinctRegions r ON st.s_nationkey IN (SELECT n.n_nationkey 
                                              FROM nation n 
                                              WHERE n.n_regionkey = r.r_regionkey)
LEFT JOIN CustomerPerformance cs ON st.s_suppkey = cs.c_custkey
WHERE st.rank <= 5 OR st.s_nationkey IS NULL
GROUP BY st.s_nationkey, r.r_name
HAVING total_customers_cost IS NOT NULL
   AND AVG(st.ps_supplycost) < (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY customer_count DESC, total_customers_cost DESC;
