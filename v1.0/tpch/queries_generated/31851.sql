WITH RECURSIVE SalesCTE AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000

    UNION ALL

    SELECT s.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM SalesCTE s
    JOIN orders o ON s.o_orderkey = o.o_orderkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'P'
    GROUP BY s.o_orderkey
),

AggregateSales AS (
    SELECT s.o_orderkey, SUM(s.total_sales) AS aggregated_sales
    FROM SalesCTE s
    GROUP BY s.o_orderkey
),

Suppliers AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)

SELECT n.n_name, COUNT(DISTINCT c.c_custkey) AS unique_customers,
       AVG(a.aggregated_sales) AS avg_order_value,
       MAX(s.total_supplycost) AS max_supply_cost,
       MIN(s.total_supplycost) AS min_supply_cost
FROM customer c
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN AggregateSales a ON a.o_orderkey = (SELECT o.o_orderkey
                                               FROM orders o
                                               WHERE o.o_custkey = c.c_custkey
                                               ORDER BY o.o_orderdate DESC
                                               LIMIT 1)
LEFT JOIN Suppliers s ON s.ps_partkey IN (SELECT l.l_partkey
                                           FROM lineitem l
                                           JOIN orders o ON l.l_orderkey = o.o_orderkey
                                           WHERE o.o_custkey = c.c_custkey)
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 5
ORDER BY n.n_name;

