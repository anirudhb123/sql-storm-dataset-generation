WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier AS s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier AS s
    JOIN SupplierHierarchy AS sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer AS c
    JOIN orders AS o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 5000
),
PartAggregates AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM part AS p
    JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationParts AS (
    SELECT n.n_name, COALESCE(SUM(pa.total_cost), 0) AS nation_total
    FROM nation AS n
    LEFT JOIN PartAggregates AS pa ON n.n_nationkey IN (
        SELECT s.s_nationkey FROM supplier AS s
        JOIN SupplierHierarchy AS sh ON s.s_suppkey = sh.s_suppkey
        WHERE sh.level = 1
    )
    GROUP BY n.n_name
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM orders AS o
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue,
    AVG(lp.l_quantity) AS avg_quantity,
    MAX(lp.l_returnflag) AS max_return_flag,
    CASE
        WHEN SUM(pa.total_cost) IS NULL THEN 'No Parts Available'
        ELSE 'Parts Available'
    END AS parts_availability,
    COUNT(DISTINCT ro.o_orderkey) AS total_orders
FROM customer AS c
JOIN TopCustomers AS tc ON c.c_custkey = tc.c_custkey
JOIN lineitem AS lp ON lp.l_orderkey IN (SELECT o.o_orderkey FROM RankedOrders AS o WHERE o.rank_order = 1)
JOIN nation AS n ON c.c_nationkey = n.n_nationkey
LEFT JOIN PartAggregates AS pa ON c.c_nationkey IN (
    SELECT s.s_nationkey FROM supplier AS s
    JOIN SupplierHierarchy AS sh ON s.s_suppkey = sh.s_suppkey
)
GROUP BY n.n_name
HAVING SUM(lp.l_extendedprice) > 10000
ORDER BY total_revenue DESC;
