WITH RankedSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           s.s_nationkey,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueOrders AS (
    SELECT o.o_orderkey,
           o.o_totalprice,
           CASE 
               WHEN o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2) THEN 'High'
               ELSE 'Low'
           END AS order_value_category
    FROM orders o
    WHERE o.o_orderstatus = 'O'
),
OrderDetails AS (
    SELECT li.l_orderkey,
           li.l_partkey,
           li.l_quantity * (1 - li.l_discount) AS net_price,
           li.l_returnflag,
           ROW_NUMBER() OVER (PARTITION BY li.l_orderkey ORDER BY li.l_linenumber) AS line_item_rank
    FROM lineitem li
),
CustomerValues AS (
    SELECT c.c_custkey,
           c.c_name,
           MAX(o.o_totalprice) AS max_order_value,
           AVG(o.o_totalprice) AS avg_order_value,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT COALESCE(c.c_name, 'Unknown Customer') AS customer_name,
       r.r_name AS nation,
       SUM(od.net_price) AS total_line_item_value,
       COUNT(DISTINCT o.o_orderkey) AS number_of_orders,
       MAX(s.total_supply_cost) AS max_supplier_cost
FROM CustomerValues c
LEFT JOIN HighValueOrders o ON c.max_order_value = o.o_totalprice
INNER JOIN OrderDetails od ON o.o_orderkey = od.l_orderkey
LEFT JOIN RankedSuppliers s ON s.rank = 1 AND s.s_nationkey = c.c_custkey
JOIN nation r ON r.n_nationkey = c.c_custkey
WHERE od.line_item_rank <= 10
AND (od.l_returnflag = 'Y' OR od.l_returnflag IS NULL)
GROUP BY c.c_custkey, c.c_name, r.r_name
HAVING SUM(od.net_price) > 1000
ORDER BY total_line_item_value DESC, customer_name;
