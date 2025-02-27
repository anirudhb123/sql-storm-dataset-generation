WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           CAST(NULL AS DECIMAL(12,2)) AS total_cost
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey IS NOT NULL)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_comment, 
           pc.ps_supplycost * CAST(NULL AS DECIMAL(12,2)) AS total_cost
    FROM partsupp pc
    JOIN SupplierChain sc ON pc.ps_suppkey = sc.s_suppkey
),
SalesSummary AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY c.c_custkey, c.c_name
),
RankedSales AS (
    SELECT s.*, RANK() OVER (PARTITION BY s.total_sales ORDER BY s.total_sales DESC) AS sales_rank
    FROM SalesSummary s
)
SELECT p.p_name, 
       COUNT(DISTINCT l.l_orderkey) AS order_count, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       MAX(NULLIF(l.l_tax, 0)) AS max_tax,
       AVG(NULLIF(l.l_discount, 0)) AS avg_discount,
       COALESCE(sc.total_cost, 0) AS supplier_total_cost
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierChain sc ON l.l_suppkey = sc.s_suppkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
  AND EXISTS (SELECT 1 FROM RankedSales rs WHERE rs.c_custkey = l.l_orderkey)
GROUP BY p.p_name
HAVING order_count > 5
ORDER BY total_revenue DESC
LIMIT 10;
