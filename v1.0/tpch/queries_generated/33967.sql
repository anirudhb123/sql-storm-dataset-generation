WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    FROM orders o
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE o.o_orderdate > oh.o_orderdate
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT oh.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_custkey
    LEFT JOIN orders o ON oh.o_orderkey = o.o_orderkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT cs.c_name, cs.order_count, cs.total_spent, 
       sp.p_name, sp.ps_availqty, sp.ps_supplycost
FROM CustomerStats cs
LEFT JOIN SupplierPartDetails sp ON cs.order_count > 0 AND sp.rn <= 3
WHERE cs.total_spent > (
    SELECT AVG(total_spent) 
    FROM CustomerStats
    WHERE order_count > 0
)
ORDER BY cs.total_spent DESC, cs.order_count ASC, sp.ps_supplycost DESC;
