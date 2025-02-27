WITH RECURSIVE OrderCTE AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate = (SELECT MAX(o2.o_orderdate) FROM orders o2)

    UNION ALL

    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_nationkey
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN OrderCTE oc ON o.o_orderkey < oc.o_orderkey
    WHERE o.o_orderdate < (SELECT MAX(o3.o_orderdate) FROM orders o3)
),
SupplierSales AS (
    SELECT ps.ps_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_partkey
),
CustomerRegion AS (
    SELECT c.c_nationkey, r.r_name, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE r.r_name IS NOT NULL
    GROUP BY c.c_nationkey, r.r_name
)
SELECT cr.r_name, COUNT(DISTINCT cr.order_count) AS total_orders,
       COALESCE(SUM(ss.total_sales), 0) AS total_sales_value, 
       AVG(ss.total_sales) AS avg_sales_value
FROM CustomerRegion cr
LEFT JOIN SupplierSales ss ON cr.c_nationkey = ss.ps_partkey
GROUP BY cr.r_name
HAVING COUNT(DISTINCT cr.order_count) > 5
ORDER BY total_sales_value DESC;
