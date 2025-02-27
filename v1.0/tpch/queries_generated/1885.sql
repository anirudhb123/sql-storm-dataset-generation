WITH OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_suppkey) AS unique_suppliers, 
           DENSE_RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT COALESCE(cs.c_name, 'Unknown Customer') AS customer_name,
       COALESCE(os.total_revenue, 0) AS order_revenue,
       cs.total_spent AS customer_spending,
       ROUND(COALESCE(os.total_revenue, 0) - COALESCE(cs.total_spent, 0), 2) AS revenue_difference,
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
FROM OrderSummary os
FULL OUTER JOIN CustomerSpending cs ON os.o_orderkey = cs.c_custkey
LEFT JOIN partsupp ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey
                                            WHERE o.o_orderkey = os.o_orderkey) -- Correlated Subquery
GROUP BY customer_name, os.total_revenue, cs.total_spent
HAVING ROUND(COALESCE(os.total_revenue, 0) - COALESCE(cs.total_spent, 0), 2) > 0
ORDER BY revenue_difference DESC;
