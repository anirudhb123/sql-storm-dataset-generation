
WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
OrderDetails AS (
    SELECT o.o_orderkey,
           o.o_custkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_discount > 0.05
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerSpending AS (
    SELECT c.c_custkey,
           c.c_name,
           COALESCE(SUM(od.net_revenue), 0) AS total_spent
    FROM customer c
    LEFT JOIN OrderDetails od ON c.c_custkey = od.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT cs.c_name,
       cs.total_spent,
       CASE
           WHEN cs.total_spent > 5000 THEN 'Premium'
           WHEN cs.total_spent BETWEEN 1000 AND 5000 THEN 'Standard'
           ELSE 'Basic'
       END AS customer_type,
       ts.total_cost AS supplier_cost
FROM CustomerSpending cs
LEFT JOIN (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
) ts ON TRUE
WHERE cs.total_spent > 2000
ORDER BY cs.total_spent DESC
LIMIT 10;
