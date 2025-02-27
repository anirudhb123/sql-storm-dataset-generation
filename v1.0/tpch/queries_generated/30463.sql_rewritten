WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS Level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.Level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.Level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalSales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
CustomerSales AS (
    SELECT c.c_custkey, SUM(os.TotalSales) AS TotalCustomerSales
    FROM customer c
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey
),
NationSales AS (
    SELECT n.n_nationkey, SUM(cs.TotalCustomerSales) AS NationTotalSales
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerSales cs ON c.c_custkey = cs.c_custkey
    GROUP BY n.n_nationkey
)
SELECT r.r_name, ns.NationTotalSales,
       CASE 
           WHEN ns.NationTotalSales IS NULL THEN 'No Sales'
           WHEN ns.NationTotalSales < 10000 THEN 'Low Sales'
           ELSE 'High Sales'
       END AS SalesCategory,
       ROW_NUMBER() OVER (ORDER BY ns.NationTotalSales DESC) AS SalesRank
FROM region r
LEFT JOIN NationSales ns ON r.r_regionkey = ns.n_nationkey
WHERE r.r_name LIKE '%East%'
ORDER BY ns.NationTotalSales DESC NULLS LAST;