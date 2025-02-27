WITH RECURSIVE recent_orders AS (
    SELECT o_orderkey, o_orderdate, o_totalprice, o_custkey, 1 AS level
    FROM orders
    WHERE o_orderdate = (SELECT MAX(o_orderdate) FROM orders)
    UNION ALL
    SELECT o.orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, ro.level + 1
    FROM orders o
    JOIN recent_orders ro ON o.o_orderdate = (SELECT MAX(o_orderdate) FROM orders WHERE o_orderdate < ro.o_orderdate)
    WHERE ro.level < 3
),
part_supplier_info AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, 
           s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice > (SELECT AVG(p_retailprice) FROM part)
),
customers_with_orders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
    HAVING COUNT(o.o_orderkey) > 0
)
SELECT ci.c_name, ci.c_acctbal, ro.o_orderkey, ro.o_totalprice, 
       psi.p_name, psi.p_retailprice, 
       CASE 
           WHEN psi.ps_availqty IS NULL THEN 'Out of Stock' 
           ELSE 'In Stock' 
       END AS stock_status
FROM customers_with_orders ci
JOIN recent_orders ro ON ci.c_custkey = ro.o_custkey
LEFT JOIN part_supplier_info psi ON ro.o_orderkey = psi.p_partkey
WHERE ci.c_acctbal > (SELECT AVG(c.c_acctbal) FROM customer c)
  AND (ro.o_totalprice > 1000 OR ci.order_count >= 5)
ORDER BY ci.c_name, ro.o_totalprice DESC
LIMIT 50;
