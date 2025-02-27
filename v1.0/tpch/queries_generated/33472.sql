WITH RECURSIVE customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer_orders co
    JOIN orders o ON co.c_custkey = o.o_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
supplier_part AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp)
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_totalprice DESC) as order_rank
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
)
SELECT co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
       sp.s_name, sp.ps_availqty,
       CASE 
           WHEN co.o_totalprice > 1000 THEN 'High Value'
           ELSE 'Standard Value' 
       END AS order_classification,
       CASE 
           WHEN l.l_returnflag IS NULL THEN 'Not Returned'
           ELSE 'Returned'
       END AS return_status
FROM customer_orders co
LEFT JOIN lineitem l ON co.o_orderkey = l.l_orderkey
LEFT JOIN supplier_part sp ON l.l_partkey = sp.ps_partkey
WHERE co.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
  AND co.c_custkey IN (
      SELECT c.c_custkey 
      FROM customer c 
      WHERE c.c_acctbal > 500
  )
  AND EXISTS (
      SELECT 1
      FROM high_value_orders hvo
      WHERE hvo.o_orderkey = co.o_orderkey
  )
ORDER BY co.o_orderdate DESC, co.o_totalprice DESC;
