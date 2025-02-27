WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level 
    FROM supplier 
    WHERE s_acctbal IS NOT NULL 
    UNION ALL 
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1 
    FROM supplier s 
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey 
        AND s.s_suppkey <> sh.s_suppkey 
        AND sh.level < 5
),
OrderLineDetails AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY l.l_orderkey DESC) AS line_no
    FROM orders o 
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE l.l_shipdate > o.o_orderdate 
          AND l.l_returnflag = 'A' 
          AND l.l_linestatus IN ('F', 'O', 'R') 
    GROUP BY o.o_orderkey, o.o_orderdate
),
HighValueCustomers AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE c.c_acctbal IS NOT NULL 
          AND o.o_orderstatus IN ('O', 'P') 
    GROUP BY c.c_custkey, c.c_name 
    HAVING SUM(o.o_totalprice) > (SELECT AVG(o2.o_totalprice) FROM orders o2) 
),
MaxLineItemRevenue AS (
    SELECT l.l_orderkey, 
           MAX(l.l_extendedprice) AS max_price 
    FROM lineitem l 
    GROUP BY l.l_orderkey
)
SELECT DISTINCT 
    r.r_name, 
    n.n_name, 
    SUM(COALESCE(ol.total_revenue, 0)) AS total_order_revenue,
    COUNT(DISTINCT c.c_custkey) AS high_value_customer_count,
    MAX(m.max_price) AS highest_line_item_price
FROM region r 
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey 
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey 
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey 
LEFT JOIN OrderLineDetails ol ON ol.o_orderkey IN (SELECT o.o_orderkey FROM orders o) 
LEFT JOIN HighValueCustomers c ON c.c_custkey IN (SELECT DISTINCT o.o_custkey FROM orders o)
LEFT JOIN MaxLineItemRevenue m ON ol.o_orderkey = m.l_orderkey
GROUP BY r.r_name, n.n_name
HAVING SUM(ol.total_revenue) > 10000 AND 
       COUNT(DISTINCT c.c_custkey) > 5
ORDER BY r.r_name ASC, n.n_name DESC;
