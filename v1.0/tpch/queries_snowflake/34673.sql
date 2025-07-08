WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
    GROUP BY o.o_orderkey
),
CustomerRegionSales AS (
    SELECT c.c_custkey, n.n_name AS nation_name, SUM(os.total_revenue) AS total_sales
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN OrderSummary os ON c.c_custkey = os.o_orderkey
    GROUP BY c.c_custkey, n.n_name
),
TopRegions AS (
    SELECT r.r_name, ROW_NUMBER() OVER (ORDER BY SUM(c.total_sales) DESC) AS rnk
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN CustomerRegionSales c ON n.n_name = c.nation_name
    GROUP BY r.r_name
    HAVING SUM(c.total_sales) > 5000
)
SELECT 
    p.p_name,
    CONCAT('Supplier: ', s.s_name, ', Region: ', r.r_name) AS supplier_region,
    MAX(COALESCE(c.total_sales, 0)) AS max_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN OrderSummary o ON o.o_orderkey = ps.ps_partkey
LEFT JOIN CustomerRegionSales c ON c.c_custkey = o.o_orderkey
JOIN TopRegions r ON r.r_name = c.nation_name
WHERE p.p_retailprice BETWEEN 10.00 AND 100.00
GROUP BY p.p_name, s.s_name, r.r_name
HAVING MAX(COALESCE(c.total_sales, 0)) > 1000
ORDER BY max_sales DESC, p.p_name;