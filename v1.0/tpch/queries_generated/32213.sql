WITH RECURSIVE CustomerRank AS (
    SELECT c_custkey, c_name, c_acctbal, 
           ROW_NUMBER() OVER (ORDER BY c_acctbal DESC) AS rank
    FROM customer
    WHERE c_acctbal IS NOT NULL
), MonthlySales AS (
    SELECT EXTRACT(YEAR FROM o_orderdate) AS order_year, 
           EXTRACT(MONTH FROM o_orderdate) AS order_month, 
           SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM orders
    JOIN lineitem ON o_orderkey = l_orderkey
    GROUP BY order_year, order_month
), SupplierPartInfo AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, 
           AVG(ps.ps_supplycost) AS avg_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_size IN (10, 20, 30)
    GROUP BY s.s_suppkey, s.s_name, p.p_partkey, p.p_name
)
SELECT c.c_name, 
       COALESCE(c.rank, 'No Rank') AS customer_rank,
       ms.order_year, 
       ms.order_month,
       ms.total_sales,
       sp.p_name, 
       sp.avg_supplycost,
       CASE WHEN ms.total_sales IS NULL THEN 'No Sales' ELSE 'Sales Recorded' END AS sales_status
FROM CustomerRank c
FULL OUTER JOIN MonthlySales ms ON c.custkey = c.custkey
LEFT JOIN SupplierPartInfo sp ON c.custkey = sp.s_suppkey
WHERE (sp.avg_supplycost IS NOT NULL AND sp.avg_supplycost < 50) 
   OR (ms.total_sales IS NOT NULL AND ms.total_sales > 10000)
ORDER BY order_year DESC, order_month DESC, c_name;
