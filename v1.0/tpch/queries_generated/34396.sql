WITH RECURSIVE SalesCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER(PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2022-01-01'
    UNION ALL
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER(PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN SalesCTE s ON s.c_custkey = c.c_custkey
    WHERE o.o_orderdate < s.o_orderdate
),
AggregatedSales AS (
    SELECT s.c_custkey, s.c_name, SUM(s.o_totalprice) AS total_sales, COUNT(s.o_orderkey) AS order_count
    FROM SalesCTE s
    WHERE s.rn <= 3
    GROUP BY s.c_custkey, s.c_name
),
PartSupplier AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > 500.00
    GROUP BY ps.ps_partkey
)
SELECT r.r_name, a.total_sales, p.total_avail_qty, 
       COALESCE(a.order_count, 0) AS order_count, 
       COALESCE(p.total_avail_qty, 0) AS avail_qty
FROM region r
LEFT JOIN (
    SELECT n.n_regionkey, SUM(a.total_sales) AS total_sales, SUM(a.order_count) AS order_count
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN AggregatedSales a ON c.c_custkey = a.c_custkey
    GROUP BY n.n_regionkey
) a ON r.r_regionkey = a.n_regionkey
LEFT JOIN (
    SELECT ps.ps_partkey, SUM(ps.total_avail_qty) AS total_avail_qty
    FROM PartSupplier ps
    GROUP BY ps.ps_partkey
) p ON a.total_sales IS NOT NULL
ORDER BY r.r_name ASC, total_sales DESC;
