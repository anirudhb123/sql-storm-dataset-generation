WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O' 
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderkey > oh.o_orderkey
), 
SupplierStats AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) as total_available, 
           AVG(ps.ps_supplycost) as average_cost
    FROM partsupp ps 
    GROUP BY ps.ps_partkey
),
CustomerOrderStats AS (
    SELECT c.c_custkey, 
           COUNT(DISTINCT o.o_orderkey) AS total_orders, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey
)
SELECT p.p_name, 
       s.s_name,
       COALESCE(so.total_orders, 0) AS customer_total_orders,
       COALESCE(ss.total_available, 0) AS supplier_total_available,
       ss.average_cost,
       CASE 
           WHEN so.total_spent >= 10000 THEN 'High Value'
           WHEN so.total_spent < 1000 THEN 'Low Value'
           ELSE 'Medium Value' 
       END AS customer_value_category
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN CustomerOrderStats so ON so.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%' || p.p_comment || '%' LIMIT 1)
JOIN SupplierStats ss ON ss.ps_partkey = p.p_partkey
WHERE p.p_retailprice BETWEEN (SELECT AVG(p2.p_retailprice) FROM part p2) * 0.9 AND (SELECT AVG(p3.p_retailprice) FROM part p3) * 1.1
  AND (p.p_size IS NULL OR p.p_size > 10)
ORDER BY customer_total_orders DESC, p.p_name;
