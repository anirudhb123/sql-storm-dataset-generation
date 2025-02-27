WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000 -- Base case for recursion

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM SupplierHierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal -- Recursive case
),
TotalSales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' AND l.l_shipdate >= DATE '2022-01-01' -- Filter for fulfilled orders
    GROUP BY l.l_partkey
),
SupplierParts AS (
    SELECT ps.ps_partkey, s.s_name, SUM(ps.ps_availqty) AS available_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN SupplierHierarchy sh ON l.l_suppkey = sh.s_suppkey
    GROUP BY s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
SalesRanking AS (
    SELECT s.s_name, s.revenue,
           RANK() OVER (ORDER BY s.revenue DESC) AS sales_rank
    FROM TopSuppliers s
)

SELECT 
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(sp.available_qty, 0) AS available_qty,
    sr.sales_rank
FROM part p
LEFT JOIN TotalSales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN SupplierParts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN SalesRanking sr ON sp.s_name = sr.s_name
WHERE p.p_retailprice > 100.00
  AND (sr.sales_rank IS NULL OR sr.sales_rank <= 5) -- Top suppliers or no sales
ORDER BY total_sales DESC, available_qty DESC;
