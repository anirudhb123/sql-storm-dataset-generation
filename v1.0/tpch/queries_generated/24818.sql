WITH RECURSIVE DiscountNations AS (
    SELECT n_nationkey, n_name, n_regionkey,
           CASE 
               WHEN EXISTS (SELECT 1 FROM supplier 
                            WHERE s_nationkey = n_nationkey 
                              AND s_acctbal > 5000) THEN 0.05
               ELSE 0.01
           END AS discount_rate
    FROM nation
    WHERE n_nationkey % 2 = 0
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
ExtendedLineItems AS (
    SELECT l.*, (l.l_extendedprice - (l.l_discount * l.l_extendedprice)) AS net_price
    FROM lineitem l
    WHERE l.l_shipmode = 'AIR' OR l.l_returnflag = 'R'
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, 
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY p.p_retailprice) OVER(PARTITION BY p.p_type) AS median_price
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 50)
)
SELECT d.n_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
       AVG(e.net_price) AS avg_net_price,
       MAX(f.median_price) AS max_median_price
FROM DiscountNations d
LEFT JOIN RankedOrders o ON d.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = o.o_custkey)
LEFT JOIN ExtendedLineItems e ON o.o_orderkey = e.l_orderkey
LEFT JOIN FilteredParts f ON f.p_partkey = e.l_partkey
WHERE d.discount_rate > 0.01
  AND (f.p_brand IS NULL OR f.p_brand LIKE 'A%')
  AND (o.o_totalprice IS NOT NULL OR e.l_discount < 0.1)
GROUP BY d.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_orders DESC, avg_net_price DESC
LIMIT 10;
