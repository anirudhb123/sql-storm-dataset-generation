WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    JOIN SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE sp.s_acctbal > sh.s_acctbal
),
CustomerProfile AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER(PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationAvgSales AS (
    SELECT n.n_nationkey, AVG(ts.total_sales) AS avg_sales
    FROM nation n
    LEFT JOIN TotalSales ts ON n.n_nationkey = (
        SELECT s.s_nationkey
        FROM supplier s
        WHERE s.s_suppkey IN (SELECT DISTINCT partsupp.ps_suppkey FROM partsupp)
    )
    GROUP BY n.n_nationkey
)
SELECT DISTINCT n.r_name, c.c_name, sh.s_name, c.c_acctbal,
       COALESCE(nas.avg_sales, 0) AS avg_sales,
       CASE WHEN c.c_acctbal > 5000 THEN 'High Value' ELSE 'Regular' END AS customer_type
FROM region n
JOIN nation_wrapped n2 ON n.r_regionkey = n2.n_regionkey
JOIN CustomerProfile c ON n2.n_nationkey = c.c_nationkey AND c.rank <= 5
LEFT JOIN SupplierHierarchy sh ON c.c_nationkey = sh.s_nationkey
LEFT JOIN NationAvgSales nas ON n2.n_nationkey = nas.n_nationkey
WHERE n.r_name LIKE '%West%'
  AND c.c_acctbal IS NOT NULL
  AND sh.level IS NULL
ORDER BY n.r_name, c.c_name;
