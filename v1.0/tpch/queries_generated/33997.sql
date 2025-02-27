WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_availqty > 0)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
SalesData AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_custkey) AS customer_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
RankedSales AS (
    SELECT 
        sd.*,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM SalesData sd
)
SELECT 
    p.p_name,
    COALESCE(r.r_name, 'UNKNOWN') AS region_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(rs.total_sales) AS max_sales,
    MIN(rs.customer_count) AS min_customers,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
JOIN RankedSales rs ON rs.o_orderkey = l.l_orderkey
JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
WHERE p.p_retailprice IS NOT NULL
AND (p.p_comment LIKE '%fragile%' OR p.p_size > 10)
GROUP BY p.p_name, r.r_name
HAVING SUM(l.l_quantity) > 50
ORDER BY p.p_name;
