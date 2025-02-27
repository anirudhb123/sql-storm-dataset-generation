WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, c.level + 1
    FROM supplier s
    JOIN SupplierCTE c ON s.s_nationkey = c.s_nationkey
    WHERE c.level < 3
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
SupplierRevenue AS (
    SELECT s.s_suppkey, s.s_name, 
           SUM(case when l.l_returnflag = 'R' then l.l_extendedprice * (1 - l.l_discount) else 0 end) AS return_revenue,
           SUM(case when l.l_returnflag <> 'R' then l.l_extendedprice * (1 - l.l_discount) else 0 end) AS non_return_revenue
    FROM SupplierCTE s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY s.s_suppkey, s.s_name
)
SELECT sr.s_suppkey, sr.s_name, 
       COALESCE(sr.non_return_revenue, 0) AS non_return_totals, 
       COALESCE(sr.return_revenue, 0) AS return_totals,
       (SELECT COUNT(DISTINCT o.o_orderkey) FROM OrderSummary o WHERE o.total_revenue > 1000) AS high_value_orders,
       CASE 
           WHEN sr.non_return_revenue > 500000 THEN 'High'
           WHEN sr.non_return_revenue BETWEEN 100000 AND 500000 THEN 'Medium'
           ELSE 'Low'
       END AS revenue_category
FROM SupplierRevenue sr
ORDER BY sr.non_return_revenue DESC
FETCH FIRST 10 ROWS ONLY;
