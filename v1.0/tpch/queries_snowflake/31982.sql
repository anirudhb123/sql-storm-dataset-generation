
WITH RECURSIVE NationCTE AS (
    SELECT n_nationkey, n_name, n_regionkey, 0 AS level
    FROM nation
    WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, c.level + 1
    FROM nation n
    INNER JOIN NationCTE c ON n.n_regionkey = c.n_nationkey
),
SupplierStats AS (
    SELECT s.s_nationkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count, AVG(s.s_acctbal) AS avg_acctbal
    FROM supplier s
    GROUP BY s.s_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
OrderInfo AS (
    SELECT o.o_orderkey, c.c_name, n.n_name AS nation_name, o.o_orderdate, 
           DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
)
SELECT d.nation_name, 
       COUNT(DISTINCT d.o_orderkey) AS total_orders, 
       SUM(COALESCE(s.supplier_count, 0)) AS total_suppliers,
       ROUND(AVG(s.avg_acctbal), 2) AS avg_supplier_acctbal,
       SUM(CASE WHEN h.total_value IS NOT NULL THEN h.total_value ELSE 0 END) AS high_value_order_sum,
       MAX(d.order_rank) AS highest_order_rank
FROM OrderInfo d
LEFT JOIN SupplierStats s ON d.nation_name = (SELECT n_name FROM nation WHERE n_nationkey = s.s_nationkey) 
GROUP BY d.nation_name
LEFT JOIN HighValueOrders h ON d.o_orderkey = h.o_orderkey
GROUP BY d.nation_name, d.o_orderkey, d.o_orderdate, d.order_rank
ORDER BY total_orders DESC, nation_name ASC;
