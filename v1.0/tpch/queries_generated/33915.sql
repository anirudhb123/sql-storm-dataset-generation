WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice, 1 AS level
    FROM orders
    WHERE o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT o2.o_orderkey, o2.o_custkey, o2.o_orderdate, o2.o_totalprice, oh.level + 1
    FROM orders o2
    JOIN OrderHierarchy oh ON o2.o_custkey = oh.o_custkey
    WHERE o2.o_orderdate > (SELECT MAX(o_orderdate) FROM orders WHERE o_custkey = oh.o_custkey) 
      AND o2.o_orderstatus = 'O'
),
PartSuppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.order_count, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    LEFT JOIN (SELECT o.o_custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS o_total_value
                FROM orders o
                WHERE o.o_orderdate >= DATE '2023-01-01'
                GROUP BY o.o_custkey) o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, o.order_count
)
SELECT
    c.c_name,
    COALESCE(o.order_count, 0) AS order_count,
    COALESCE(o.total_order_value, 0.00) AS total_order_value,
    p.p_name,
    ph.total_supplycost
FROM customer c
LEFT JOIN CustomerOrders o ON c.c_custkey = o.c_custkey
LEFT JOIN PartSuppliers ph ON ph.ps_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey IN (
        SELECT oh.o_orderkey
        FROM OrderHierarchy oh
    )
)
JOIN part p ON p.p_partkey = ph.ps_partkey
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
  AND (o.order_count IS NULL OR o.order_count > 5)
ORDER BY total_order_value DESC, c.c_name;
