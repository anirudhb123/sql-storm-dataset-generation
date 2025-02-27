WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
), HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
), NationsAndRegions AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT n_r.n_name AS Nation, r.r_name AS Region, 
       COUNT(DISTINCT h_o.o_orderkey) AS High_Value_Orders,
       COALESCE(SUM(s_av.ps_availqty), 0) AS Total_Availability,
       MAX(h_o.total_value) AS Max_Order_Value
FROM NationsAndRegions n_r
LEFT JOIN HighValueOrders h_o ON n_r.n_nationkey = (
    SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = h_o.o_custkey
) LEFT JOIN SupplyChain s_av ON s_av.ps_partkey IN (
    SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = h_o.o_orderkey
)
GROUP BY n_r.n_name, r.r_name
HAVING COUNT(DISTINCT h_o.o_orderkey) > 0 OR SUM(s_av.ps_availqty) IS NOT NULL
ORDER BY Max_Order_Value DESC, Nation ASC;
