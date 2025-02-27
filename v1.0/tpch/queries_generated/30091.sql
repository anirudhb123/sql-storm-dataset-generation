WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice,
           o_orderdate, o_orderpriority, o_clerk, o_shippriority, o_comment,
           1 AS level
    FROM orders
    WHERE o_orderpriority = 'HIGH'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice,
           o.o_orderdate, o.o_orderpriority, o.o_clerk, o.o_shippriority, o.o_comment,
           oh.level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > '2022-01-01' AND o.o_orderstatus = 'O'
),
PartSupplierInfo AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available,
           SUM(ps.ps_supplycost) AS total_cost, 
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
CustomerOrderStats AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT DISTINCT ch.o_clerk, ch.o_orderdate, ch.o_orderstatus,
                COALESCE(cos.order_count, 0) AS customer_orders,
                COALESCE(cos.total_spent, 0) AS total_spent,
                psi.p_name, psi.total_available, psi.total_cost
FROM OrderHierarchy ch
LEFT JOIN CustomerOrderStats cos ON ch.o_custkey = cos.c_custkey
LEFT JOIN PartSupplierInfo psi ON psi.rank = 1
WHERE ch.o_shippriority IS NOT NULL
AND (psi.total_cost - psi.total_available * 1.1) > 0
ORDER BY ch.o_orderdate DESC, cos.total_spent DESC
LIMIT 50;
