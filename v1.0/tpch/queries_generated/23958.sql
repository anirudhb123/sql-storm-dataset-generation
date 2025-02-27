WITH RecursiveSupplierCTE AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS recursion_level
    FROM supplier
    WHERE s_acctbal > 2000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, r.recursion_level + 1
    FROM supplier s
    JOIN RecursiveSupplierCTE r ON s.s_nationkey = r.s_nationkey
    WHERE r.recursion_level < 5
), PartPriceCalculation AS (
    SELECT p.p_partkey, p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), OrderAnalysis AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F' 
    AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderdate = o.o_orderdate)
)
SELECT r.r_name, 
       COUNT(DISTINCT cs.cust_orders) AS unique_customer_orders,
       AVG(psc.total_supplycost) AS avg_supplycost,
       MAX(oa.price_rank) AS max_order_rank
FROM region r
LEFT JOIN (
    SELECT n.n_nationkey, 
           COUNT(DISTINCT o.o_orderkey) AS cust_orders
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey
) cs ON cs.n_nationkey = r.r_regionkey
JOIN PartPriceCalculation psc ON psc.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 10)
LEFT JOIN OrderAnalysis oa ON oa.o_orderkey = (
    SELECT o_orderkey 
    FROM orders 
    WHERE o_orderdate = (CURRENT_DATE - INTERVAL '30 day') 
    ORDER BY o_totalprice DESC 
    LIMIT 1
)
GROUP BY r.r_name
HAVING COUNT(DISTINCT cs.cust_orders) > 0
AND MAX(oa.price_rank) IS NOT NULL
ORDER BY r.r_name;
