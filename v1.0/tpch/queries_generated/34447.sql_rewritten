WITH RECURSIVE CTE_Supplier_Costs AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), 
CTE_Order_Summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATE '1996-01-01' 
)
SELECT p.p_name, p.p_brand, p.p_type, 
       SUM(l.l_quantity) AS total_quantity, 
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       (SELECT COUNT(DISTINCT c.c_custkey) 
        FROM customer c 
        WHERE c.c_nationkey IN (SELECT n.n_nationkey 
                                FROM nation n 
                                WHERE n.n_regionkey = 1)) AS customer_count_region,
       COALESCE(MAX(sc.total_supply_cost), 0) AS max_supply_cost
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN CTE_Order_Summary o ON l.l_orderkey = o.o_orderkey
LEFT JOIN CTE_Supplier_Costs sc ON p.p_partkey = (SELECT ps.ps_partkey 
                                                   FROM partsupp ps 
                                                   WHERE ps.ps_suppkey = sc.s_suppkey 
                                                   LIMIT 1)
GROUP BY p.p_name, p.p_brand, p.p_type
HAVING COUNT(DISTINCT o.o_orderkey) > 5 
   AND AVG(l.l_extendedprice * (1 - l.l_discount)) > 100
ORDER BY total_quantity DESC
LIMIT 10;