WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_orderstatus = 'O'
      AND o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
),
SupplierPartDetails AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_retailprice
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0
),
OrderLineItem AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, 
           l.l_discount, l.l_tax,
           (l.l_extendedprice * (1 - l.l_discount) + l.l_tax) AS net_price
    FROM lineitem l
    WHERE l.l_shipdate < CURRENT_DATE - INTERVAL '30 days'
)
SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS total_orders, 
       SUM(oli.net_price) AS total_revenue,
       AVG(sp.ps_supplycost) AS avg_supply_cost,
       MAX(sp.p_retailprice) AS max_retail_price,
       COUNT(DISTINCT sh.s_suppkey) AS unique_suppliers
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN HighValueOrders o ON c.c_custkey = o.o_orderkey
LEFT JOIN OrderLineItem oli ON o.o_orderkey = oli.l_orderkey
LEFT JOIN SupplierPartDetails sp ON oli.l_partkey = sp.ps_partkey
LEFT JOIN SupplierHierarchy sh ON sp.ps_suppkey = sh.s_suppkey
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
