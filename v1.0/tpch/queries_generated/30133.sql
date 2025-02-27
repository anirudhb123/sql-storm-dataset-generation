WITH RECURSIVE CTE_SupplierCosts AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_supplycost, 
           ps.ps_availqty, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           1 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100
    UNION ALL
    SELECT s.s_suppkey, s.s_name, ps.ps_supplycost, 
           ps.ps_availqty, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           cte.level + 1
    FROM CTE_SupplierCosts cte
    JOIN partsupp ps ON ps.ps_partkey = (
        SELECT p.p_partkey 
        FROM part p 
        WHERE p.p_retailprice > 20
        ORDER BY p.p_retailprice ASC 
        LIMIT 1
    ) 
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE cte.total_cost < 10000 AND ps.ps_availqty < 50
),
CustomerStats AS (
    SELECT c.c_custkey, c.c_name, 
           COUNT(o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING COUNT(o.o_orderkey) > 5
)
SELECT n.n_name, 
       COUNT(DISTINCT cs.c_custkey) AS customer_count,
       SUM(cs.total_spent) AS total_revenue,
       AVG(cs.order_count) AS average_orders,
       AVG(s.total_cost) AS avg_supplier_cost
FROM nation n
LEFT JOIN CustomerStats cs ON cs.c_nationkey = n.n_nationkey
LEFT JOIN CTE_SupplierCosts s ON s.s_suppkey IN (
    SELECT ps.ps_suppkey FROM partsupp ps
    WHERE ps.ps_availqty > 0
)
GROUP BY n.n_name
ORDER BY total_revenue DESC
LIMIT 10;
