WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, 0 AS level
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.c_acctbal > ch.c_acctbal
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
TopSuppliers AS (
    SELECT ps.ps_suppkey, SUM(ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey
    HAVING SUM(ps.ps_supplycost) > (
        SELECT AVG(ps2.ps_supplycost)
        FROM partsupp ps2
    )
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_suppkey = ts.ps_suppkey
),
AggregateOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_custkey
),
FinalAggregation AS (
    SELECT c.c_name, coalesce(ao.total_spent, 0) AS total_spent,
           COUNT(DISTINCT ro.o_orderkey) AS order_count,
           ROW_NUMBER() OVER (ORDER BY coalesce(ao.total_spent, 0) DESC) AS rank
    FROM customer c
    LEFT JOIN AggregateOrders ao ON c.c_custkey = ao.c_custkey
    LEFT JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
    GROUP BY c.c_name, ao.total_spent
)
SELECT fh.c_name, fh.total_spent, fh.order_count, 
       r.r_name AS region,
       ROW_NUMBER() OVER (PARTITION BY fh.region ORDER BY fh.total_spent DESC) AS regional_rank
FROM FinalAggregation fh
JOIN nation n ON fh.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE fh.total_spent IS NOT NULL
ORDER BY region, total_spent DESC
LIMIT 100;
