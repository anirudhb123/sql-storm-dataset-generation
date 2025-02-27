WITH RECURSIVE CustomerOrderCTE AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrderCTE co ON c.c_custkey = co.c_custkey
    WHERE co.o_orderkey IS NOT NULL
),
SupplierSales AS (
    SELECT ps.ps_suppkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY ps.ps_suppkey
),
OrderDetails AS (
    SELECT o.o_orderkey, COUNT(l.l_linenumber) AS line_item_count, AVG(l.l_discount) AS avg_discount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationRegion AS (
    SELECT n.n_nationkey, n.n_name, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    co.c_name AS customer_name,
    co.o_orderkey,
    co.o_orderdate,
    od.line_item_count,
    od.avg_discount,
    COALESCE(ss.total_sales, 0) AS total_sales,
    nr.r_name AS region_name,
    CASE WHEN COALESCE(ss.total_sales, 0) > 10000 THEN 'High Value' ELSE 'Low Value' END AS sales_category
FROM CustomerOrderCTE co
LEFT JOIN OrderDetails od ON co.o_orderkey = od.o_orderkey
LEFT JOIN SupplierSales ss ON ss.ps_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps ORDER BY ps.ps_supplycost DESC LIMIT 1)
LEFT JOIN NationRegion nr ON nr.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
WHERE co.o_orderdate >= '2023-01-01' OR od.line_item_count > 5
ORDER BY co.o_orderdate DESC, total_sales DESC;
