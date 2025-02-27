WITH RECURSIVE OrderAggregation AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey, o.o_orderstatus
),
TopOrders AS (
    SELECT o_orderkey, 
           o_orderstatus, 
           ROW_NUMBER() OVER (PARTITION BY o_orderstatus ORDER BY total_sales DESC) AS rank
    FROM OrderAggregation
),
SupplierSales AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
MultiRegionNation AS (
    SELECT n.n_nationkey,
           n.n_name,
           r.r_regionkey,
           r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
)
SELECT TOP 10 
       r.r_name AS region,
       n.n_name AS nation,
       COALESCE(SUM(ots.total_sales), 0) AS total_order_sales,
       COALESCE(ss.total_supplycost, 0) AS total_supply_cost,
       CASE 
           WHEN SUM(ots.total_sales) > 1000000 THEN 'High Value'
           WHEN SUM(ots.total_sales) IS NULL THEN 'No Sales'
           ELSE 'Medium Value'
       END AS sales_category
FROM MultiRegionNation m
LEFT JOIN TopOrders ots ON m.n_nationkey IN (
    SELECT DISTINCT n_nationkey FROM nation
) 
LEFT JOIN SupplierSales ss ON ss.s_suppkey IN (
    SELECT ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey IN (
        SELECT p.p_partkey FROM part p
        WHERE p.p_retailprice > 100
    )
)
JOIN region r ON m.r_regionkey = r.r_regionkey
JOIN nation n ON m.n_nationkey = n.n_nationkey
GROUP BY r.r_name, n.n_name
ORDER BY sales_category DESC, total_order_sales DESC;
