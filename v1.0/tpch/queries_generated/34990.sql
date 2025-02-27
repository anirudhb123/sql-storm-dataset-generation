WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, 1 AS order_level
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice, oh.order_level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate AND o.o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, l.l_discount, 
           RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.15 AND l.l_returnflag = 'N'
),
TotalOrderCost AS (
    SELECT oh.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost_after_discount
    FROM OrderHierarchy oh
    JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
    GROUP BY oh.o_orderkey
)
SELECT p.p_name, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count, 
       SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_available_qty,
       AVG(SUM(toc.total_cost_after_discount)) AS avg_total_cost
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN TotalOrderCost toc ON toc.o_orderkey = 
    (SELECT o.o_orderkey 
     FROM orders o 
     WHERE o.o_custkey = c.c_custkey 
     ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) 
                          FROM part p2 
                          WHERE p2.p_size >= p.p_size)
GROUP BY p.p_name, r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 1
ORDER BY customer_count DESC, avg_total_cost DESC
LIMIT 10;
