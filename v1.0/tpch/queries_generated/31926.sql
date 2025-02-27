WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, 1 AS lvl
    FROM customer
    WHERE c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
    UNION ALL
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.lvl + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    WHERE ch.lvl < 5
),
DistinctPartCosts AS (
    SELECT DISTINCT ps.ps_partkey, ps.ps_supplycost, p.p_name
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost > 50
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY o.o_orderkey
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_availqty) AS total_available_quantity
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT c.c_name,
       COALESCE(SUM(a.total_revenue), 0) AS total_revenue,
       AVG(d.ps_supplycost) AS average_supply_cost,
       s.total_available_quantity,
       ROW_NUMBER() OVER (PARTITION BY s.total_available_quantity ORDER BY SUM(a.total_revenue) DESC) AS revenue_rank
FROM CustomerHierarchy c
LEFT JOIN AggregatedOrders a ON c.c_custkey = a.o_orderkey
JOIN DistinctPartCosts d ON a.o_orderkey = d.ps_partkey
JOIN SupplierDetails s ON d.ps_partkey = d.ps_partkey
WHERE s.total_available_quantity IS NOT NULL
GROUP BY c.c_name, s.total_available_quantity
HAVING AVG(d.ps_supplycost) < 100
ORDER BY revenue_rank, total_revenue DESC;
