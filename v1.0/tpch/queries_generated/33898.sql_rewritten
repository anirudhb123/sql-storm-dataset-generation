WITH RECURSIVE NationHierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_nationkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, h.level + 1
    FROM nation n
    JOIN NationHierarchy h ON n.n_regionkey = h.n_nationkey
),
SupplierStats AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_quantity,
           AVG(ps.ps_supplycost) AS average_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemMetrics AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
           COUNT(*) AS item_count,
           MAX(l.l_shipdate) AS latest_ship_date
    FROM lineitem l
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY l.l_orderkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, 
           COALESCE(MAX(o.o_totalprice), 0) AS max_order_value,
           COUNT(o.o_orderkey) AS num_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT p.p_partkey,
       p.p_name,
       COALESCE(s.total_available_quantity, 0) AS available_quantity,
       s.average_supply_cost,
       l.total_sales,
       c.max_order_value,
       c.num_orders,
       CASE 
           WHEN l.total_sales IS NULL THEN 'No Sales' 
           ELSE 'Sales Recorded' 
       END AS sales_status,
       r.r_name AS region_name
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN SupplierStats s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN LineItemMetrics l ON p.p_partkey = l.l_orderkey
LEFT JOIN CustomerOrderSummary c ON c.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%CUSTOMER%' LIMIT 1)
JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MAX(n_nationkey) FROM nation))
WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
ORDER BY p.p_partkey;