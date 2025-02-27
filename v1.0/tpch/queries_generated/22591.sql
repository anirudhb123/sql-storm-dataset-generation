WITH RECURSIVE supplier_ranks AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
price_analysis AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost) AS total_supply_cost,
           AVG(p.p_retailprice) AS average_retail_price,
           COUNT(DISTINCT ps.ps_suppkey) AS unique_suppliers
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey,
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS recent_order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
),
taxed_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           (l.l_extendedprice * (1 - l.l_discount)) * (1 + l.l_tax) AS final_price
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
),
sufficient_inventory AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
           CASE WHEN ps.ps_availqty < 10 THEN 'Low Stock' ELSE 'Sufficient Stock' END AS stock_status
    FROM partsupp ps
)
SELECT c.c_name, p.p_name, sa.total_supply_cost, 
       pa.average_retail_price, co.recent_order_rank,
       li.final_price, si.stock_status
FROM customer_orders co
JOIN customer c ON co.c_custkey = c.c_custkey
JOIN price_analysis pa ON pa.p_partkey IN (
    SELECT p_partkey 
    FROM part 
    WHERE p_size BETWEEN 10 AND 50
) 
LEFT OUTER JOIN supplier_ranks sr ON c.c_nationkey = sr.s_nationkey AND sr.rank = 1
JOIN taxed_lineitems li ON li.l_orderkey = co.o_orderkey
JOIN sufficient_inventory si ON si.ps_partkey = li.l_partkey
WHERE (c.c_acctbal IS NOT NULL AND c.c_acctbal > 1000)
  OR (co.o_orderkey IN (
      SELECT o_orderkey FROM orders 
      WHERE o_orderstatus = 'O' 
      AND o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
  ))
ORDER BY final_price DESC, total_supply_cost ASC
FETCH FIRST 100 ROWS ONLY;
