WITH RECURSIVE OrderHistory AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE c.c_acctbal > (SELECT AVG(ca.c_acctbal)
                         FROM customer ca
                         WHERE ca.c_mktsegment = c.c_mktsegment)
),
SuspiciousSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost) > 1000
),
HighValueOrders AS (
    SELECT oh.o_orderkey, oh.o_orderdate, oh.o_totalprice, 
           DENSE_RANK() OVER (ORDER BY oh.o_totalprice DESC) AS price_rank
    FROM OrderHistory oh
    WHERE oh.o_orderstatus = 'O'
)
SELECT DISTINCT pl.p_name, 
                (CASE WHEN s_total.total_supply_cost IS NULL THEN 'Unknown' ELSE s_total.total_supply_cost END) AS supplier_cost,
                (CASE WHEN high_orders.price_rank <= 5 THEN 'High' ELSE 'Regular' END) AS order_value_category
FROM part pl
LEFT JOIN (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
) AS s_total ON pl.p_partkey = s_total.ps_partkey
LEFT JOIN HighValueOrders high_orders ON high_orders.o_orderkey = (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = pl.p_partkey 
      AND l.l_shipdate > '2023-01-01' 
      AND l.l_returnflag <> 'R' 
    ORDER BY l.l_extendedprice DESC 
    LIMIT 1
)
WHERE EXISTS (
    SELECT 1
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_name LIKE '%Supplier%' AND r.r_name IS NOT NULL
)
ORDER BY supplier_cost NULLS LAST, pl.p_name
LIMIT 100;
