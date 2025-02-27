WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, p.p_name
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100

    UNION ALL

    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, p.p_name
    FROM SupplyChain sc
    JOIN supplier s ON s.s_suppkey = sc.s_suppkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 100
)

SELECT n.n_name AS nation_name, 
       SUM(ps.ps_supplycost * l.l_quantity) AS total_cost, 
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(o.o_totalprice) AS avg_order_value
FROM SupplyChain sc
JOIN orders o ON o.o_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'AMERICA')))
JOIN lineitem l ON l.l_orderkey = o.o_orderkey 
JOIN part p ON p.p_partkey = sc.ps_partkey
JOIN supplier s ON s.s_suppkey = sc.s_suppkey
JOIN nation n ON n.n_nationkey = s.s_nationkey
GROUP BY n.n_name
HAVING SUM(ps.ps_availqty) > 1000
ORDER BY total_cost DESC
LIMIT 10;
