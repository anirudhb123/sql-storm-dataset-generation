WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_totalprice, o_orderdate,
           0 AS Level
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice, o.o_orderdate,
           oh.Level + 1
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderDetails AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           STRING_AGG(DISTINCT CAST(o.o_orderkey AS VARCHAR), ', ') AS order_keys
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT oh.o_orderkey, oh.o_orderdate, s.s_name, so.total_cost, cod.c_name, cod.order_count, cod.total_spent
FROM OrderHierarchy oh
LEFT JOIN RankedSuppliers s ON s.rank = 1
LEFT JOIN CustomerOrderDetails cod ON cod.c_custkey = oh.o_custkey
JOIN lineitem l ON l.l_orderkey = oh.o_orderkey
WHERE l.l_discount > 0.1 AND (so.total_cost IS NOT NULL OR so.total_cost < 500)
ORDER BY oh.o_orderdate DESC, cod.total_spent DESC
LIMIT 100;
