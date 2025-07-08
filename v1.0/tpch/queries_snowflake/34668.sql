
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, h.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy h ON s.s_suppkey = h.s_suppkey
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
NationRevenue AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(SUM(a.total_revenue), 0) AS total_revenue
    FROM nation n
    LEFT JOIN AggregatedOrders a ON n.n_nationkey = (
        SELECT c.c_nationkey 
        FROM customer c 
        WHERE c.c_custkey = (
            SELECT o.o_custkey 
            FROM orders o 
            WHERE o.o_orderkey = a.o_orderkey 
            LIMIT 1
        )
    )
    GROUP BY n.n_nationkey, n.n_name
),
RankedRevenue AS (
    SELECT n.n_name, n.total_revenue,
           RANK() OVER (ORDER BY n.total_revenue DESC) AS revenue_rank
    FROM NationRevenue n
)
SELECT p.p_name, 
       COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
       AVG(ps.ps_supplycost) AS avg_supply_cost, 
       COALESCE(nr.total_revenue, 0) AS nation_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN RankedRevenue nr ON ps.ps_suppkey = (
    SELECT s.s_suppkey 
    FROM supplier s 
    WHERE s.s_nationkey = (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_name = 'USA'
    )
)
GROUP BY p.p_name, nr.total_revenue
HAVING AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY supplier_count DESC, avg_supply_cost ASC
LIMIT 10;
