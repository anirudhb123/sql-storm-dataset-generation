WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal >= 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal
    WHERE s.s_suppkey <> sh.s_suppkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT li.l_partkey) AS distinct_parts,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS sales_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey
),
TopOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, os.total_sales
    FROM orders o
    JOIN OrderStats os ON o.o_orderkey = os.o_orderkey
    WHERE os.sales_rank <= 5
),
SupplierOrders AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(to.total_sales) AS total_from_orders
    FROM SupplierHierarchy sh
    LEFT JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN lineitem li ON p.p_partkey = li.l_partkey
    JOIN TopOrders to ON li.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= '2023-01-01')
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(to.total_sales) IS NOT NULL 
)
SELECT r.r_name, COUNT(DISTINCT so.s_suppkey) AS supplier_count, SUM(so.total_from_orders) AS total_sales_per_region
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierOrders so ON s.s_suppkey = so.s_suppkey
GROUP BY r.r_name
ORDER BY total_sales_per_region DESC
LIMIT 10;
