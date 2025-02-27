WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
PercentageCTE AS (
    SELECT p.p_partkey, p.p_name, p.p_brand,
           (p.p_retailprice / NULLIF(SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey), 0)) * 100) AS price_percentage
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
AggregatedSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01'
    GROUP BY o.o_orderkey
),
FinalOutput AS (
    SELECT r.r_name, n.n_name, SUM(COALESCE(ps.ps_availqty, 0)) AS total_available,
           MAX(pc.price_percentage) AS max_price_percentage,
           SUM(as.total_sales) AS total_revenue,
           COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN PercentageCTE pc ON pc.p_partkey = ps.ps_partkey
    LEFT JOIN AggregatedSales as ON as.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE o.o_orderstatus IN ('F', 'O')
    )
    GROUP BY r.r_name, n.n_name
    HAVING SUM(COALESCE(ps.ps_availqty, 0)) > 1000
           AND MAX(pc.price_percentage) IS NOT NULL
           AND COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT f.r_name, f.n_name, f.total_available, f.max_price_percentage, f.total_revenue, 
       CASE 
           WHEN f.total_revenue > 1000000 THEN 'High'
           WHEN f.total_revenue BETWEEN 500000 AND 1000000 THEN 'Medium'
           ELSE 'Low' 
       END AS revenue_category,
       CASE 
           WHEN f.total_available IS NULL THEN 'No Supply'
           ELSE 'Supplied'
       END AS supply_status
FROM FinalOutput f
ORDER BY f.total_revenue DESC, f.r_name;
