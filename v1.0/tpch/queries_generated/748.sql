WITH RankedOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice, 
           o.o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
),
SupplierSummary AS (
    SELECT s.s_suppkey, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
CustomerAnalysis AS (
    SELECT c.c_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartDetails AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_availqty) AS available_stock, 
           MAX(p.p_retailprice * (1 - COALESCE(NULLIF(line_item.l_discount, 0), 0))) AS max_retail_after_discount
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem line_item ON ps.ps_partkey = line_item.l_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT r.r_name, 
       SUM(s.total_available) AS total_supplier_availability, 
       SUM(c.total_orders) AS total_orders_placed, 
       AVG(c.total_spent) AS avg_spent_per_customer, 
       COUNT(DISTINCT po.p_partkey) AS unique_parts_sourced
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN CustomerAnalysis c ON s.s_suppkey = c.c_custkey
LEFT JOIN PartDetails po ON po.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
WHERE r.r_name IS NOT NULL AND c.total_orders > 0
GROUP BY r.r_name
ORDER BY total_supplier_availability DESC, avg_spent_per_customer DESC
LIMIT 10;
