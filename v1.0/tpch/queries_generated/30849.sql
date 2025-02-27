WITH RECURSIVE SupplyChain AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > 100.00

    UNION ALL

    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, s.s_name, s.s_nationkey,
           ROW_NUMBER() OVER(PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice <= 100.00 AND s.s_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name LIKE 'A%'
    )
)

SELECT n.n_name, 
       COUNT(DISTINCT sc.p_partkey) AS part_count, 
       SUM(sc.ps_supplycost) AS total_supply_cost,
       AVG(sc.ps_supplycost) AS avg_supply_cost
FROM SupplyChain sc
JOIN supplier s ON sc.s_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT sc.p_partkey) > 5
ORDER BY avg_supply_cost DESC;

WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus, 
           DENSE_RANK() OVER (ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'F'
)

SELECT ro.o_orderkey, 
       ro.o_totalprice, 
       r.r_name AS region_name, 
       COALESCE(l.l_discount, 0) AS discount_applied
FROM RankedOrders ro
FULL OUTER JOIN lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN customer c ON ro.o_orderkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE (l.l_discount > 0 OR l.l_discount IS NULL)
AND ro.order_rank <= 10
ORDER BY ro.o_totalprice DESC;
