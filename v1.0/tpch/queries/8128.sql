WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
),
CustomerOrderStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'P')
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.o_orderkey, r.o_orderdate, r.o_totalprice, 
       cs.c_name, cs.order_count, cs.total_spent, cs.avg_order_value, 
       ts.s_name, ts.total_cost
FROM RankedOrders r
JOIN CustomerOrderStats cs ON r.o_orderkey IN (
    SELECT o.o_orderkey
    FROM orders o
    WHERE o.o_custkey = cs.c_custkey
)
JOIN TopSuppliers ts ON ts.total_cost > 20000
WHERE r.rank <= 10
ORDER BY r.o_orderdate DESC, r.o_totalprice DESC;