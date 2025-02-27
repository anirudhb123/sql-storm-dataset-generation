WITH RECURSIVE SupplierSales AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATE '1997-01-01'
      AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
RankedSales AS (
    SELECT s.s_suppkey,
           s.s_name,
           ss.total_sales,
           ROW_NUMBER() OVER (ORDER BY ss.total_sales DESC) AS sales_rank
    FROM supplier s
    LEFT JOIN SupplierSales ss ON s.s_suppkey = ss.s_suppkey
),
TopSuppliers AS (
    SELECT *
    FROM RankedSales
    WHERE sales_rank <= 10
)
SELECT COALESCE(c.c_name, 'UNKNOWN CUSTOMER') AS customer_name,
       COALESCE(n.n_name, 'UNKNOWN NATION') AS supplier_nation,
       ts.s_name AS top_supplier,
       ts.total_sales AS total_sales
FROM TopSuppliers ts
FULL OUTER JOIN customer c ON c.c_custkey = (SELECT MAX(o.o_custkey)
                                              FROM orders o
                                              JOIN lineitem l ON o.o_orderkey = l.l_orderkey
                                              WHERE l.l_suppkey = ts.s_suppkey
                                                AND l.l_returnflag = 'N')
LEFT JOIN nation n ON n.n_nationkey = c.c_nationkey
WHERE ts.total_sales IS NOT NULL
ORDER BY total_sales DESC NULLS LAST;