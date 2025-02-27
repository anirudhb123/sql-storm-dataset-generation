WITH RECURSIVE CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
FrequentSuppliers AS (
    SELECT s.s_suppkey, s.s_name, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING COUNT(DISTINCT ps.ps_partkey) > 5
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS line_count, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT cs.c_name, 
       fs.s_name AS supplier_name,
       od.line_count,
       od.order_total,
       CASE WHEN od.order_total > 5000 THEN 'High Value Order' ELSE 'Regular Order' END AS order_category,
       RANK() OVER (PARTITION BY cs.c_custkey ORDER BY od.order_total DESC) AS rank_within_customer
FROM CustomerSpending cs
JOIN OrderDetails od ON cs.c_custkey = od.o_orderkey
LEFT JOIN FrequentSuppliers fs ON fs.parts_supplied > 5
WHERE od.order_total IS NOT NULL
  AND fs.s_name IS NOT NULL 
  AND cs.total_spent IS NOT NULL
ORDER BY cs.c_name, od.order_total DESC;
