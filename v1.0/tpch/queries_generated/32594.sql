WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
  
    UNION ALL
  
    SELECT o.o_orderkey, o.o_custkey, oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderstatus = 'O'
      AND o.o_orderkey > oh.o_orderkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey,
           c.c_name,
           COALESCE(SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END), 0) AS total_open_orders,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierInfo AS (
    SELECT p.p_partkey, 
           p.p_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)

SELECT ch.c_name, 
       ch.total_open_orders, 
       ch.order_count, 
       ch.avg_order_value,
       psi.p_name,
       psi.total_supply_value,
       ts.s_name AS top_supplier_name
FROM CustomerOrderSummary ch
JOIN PartSupplierInfo psi ON ch.order_count > 1
LEFT JOIN TopSuppliers ts ON psi.rank = 1
WHERE (ch.total_open_orders > 1000 OR ch.order_count > 10)
ORDER BY ch.total_open_orders DESC, ch.avg_order_value ASC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
