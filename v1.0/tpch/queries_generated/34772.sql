WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
TopSuppliers AS (
    SELECT s_name, SUM(ps_supplycost) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s_name
    HAVING SUM(ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
CustomerSummary AS (
    SELECT c.c_custkey, c.c_mktsegment, COUNT(o.o_orderkey) AS order_count,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_mktsegment
)
SELECT
    r.r_name AS region_name,
    sub.s_name AS supplier_name,
    SUM(COALESCE(ts.total_supplycost, 0)) AS supplier_total_supplycost,
    COUNT(DISTINCT cs.c_custkey) AS customer_count,
    AVG(cs.order_count) AS avg_orders_per_customer,
    SUM(cs.total_spent) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(cs.total_spent) DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY SUM(cs.total_spent) DESC) AS dense_rank
FROM region r
JOIN nation n ON n.n_regionkey = r.r_regionkey
JOIN supplier sub ON sub.s_nationkey = n.n_nationkey
LEFT JOIN TopSuppliers ts ON sub.s_name = ts.s_name
LEFT JOIN CustomerSummary cs ON cs.c_mktsegment = 'BUILDING'
WHERE sub.s_nationkey IS NOT NULL
GROUP BY r.r_name, sub.s_name
HAVING COUNT(DISTINCT cs.c_custkey) > 5
ORDER BY region_name, total_sales DESC;
