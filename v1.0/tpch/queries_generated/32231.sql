WITH RECURSIVE PartSuppliers AS (
    SELECT ps.ps_partkey, s.s_name AS supplier_name, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
), 
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' 
    GROUP BY o.o_orderkey, o.o_orderdate
    HAVING total_order_value > 5000
), 
AdditionalData AS (
    SELECT c.c_name, c.c_mktsegment, o.total_order_value, r.r_name AS region
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT p.p_name, 
       COALESCE(s.supplier_name, 'No Supplier') AS supplier_name, 
       COALESCE(ad.region, 'No Region') AS order_region,
       SUM(COALESCE(ad.total_order_value, 0)) AS total_value,
       AVG(COALESCE(p.p_retailprice, 0)) AS avg_price,
       COUNT(DISTINCT ad.c_name) AS customer_count
FROM part p
LEFT JOIN PartSuppliers s ON p.p_partkey = s.ps_partkey AND s.rank = 1
LEFT JOIN AdditionalData ad ON ad.total_order_value > 0
WHERE p.p_size > 10
GROUP BY p.p_name, s.supplier_name, ad.region
ORDER BY total_value DESC, avg_price ASC
LIMIT 100;
