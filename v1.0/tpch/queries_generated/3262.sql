WITH SupplierSales AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, ss.total_sales,
           RANK() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE ss.total_sales IS NOT NULL
)
SELECT ns.n_name AS nation_name,
       COALESCE(ts.s_name, 'Unknown Supplier') AS supplier_name,
       COALESCE(ts.total_sales, 0) AS total_sales,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       ROUND(AVG(o.o_totalprice), 2) AS average_order_price
FROM nation ns
LEFT JOIN supplier s ON s.s_nationkey = ns.n_nationkey
LEFT JOIN TopSuppliers ts ON s.s_suppkey = ts.s_suppkey
LEFT JOIN orders o ON o.o_custkey IN (
    SELECT c.c_custkey
    FROM customer c
    WHERE c.c_nationkey = ns.n_nationkey AND c.c_acctbal > 500
)
WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY ns.n_name, ts.s_name, ts.total_sales
HAVING COUNT(DISTINCT o.o_orderkey) > 5 OR ts.total_sales > 100000
ORDER BY nation_name, total_sales DESC;
