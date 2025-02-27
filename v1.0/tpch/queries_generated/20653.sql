WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM supplier s
    JOIN SupplierCTE cte ON s.s_suppkey = (cte.s_suppkey % (SELECT COUNT(*) FROM supplier)) + 1
    WHERE cte.level < 3
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, SUM(ps.ps_supplycost) AS total_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),
CustomerInfo AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY c.c_custkey
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           AVG(l.l_quantity) OVER (PARTITION BY o.o_orderkey) AS avg_line_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('F', 'P')
    GROUP BY o.o_orderkey
),
DenseRankedOrders AS (
    SELECT o.*, DENSE_RANK() OVER (ORDER BY os.net_revenue DESC) AS revenue_rank
    FROM OrderSummary os
    JOIN orders o ON os.o_orderkey = o.o_orderkey
)
SELECT DISTINCT pd.p_partkey, pd.p_name, pd.p_retailprice, 
       COALESCE(cust.order_count, 0) AS order_count, 
       scte.level AS supplier_level, 
       dro.revenue_rank, 
       CASE 
           WHEN dro.avg_line_quantity IS NULL THEN 'No Orders' 
           ELSE CONCAT('Avg Qty: ', CAST(dro.avg_line_quantity AS VARCHAR)) 
       END AS order_summary
FROM PartDetails pd
LEFT JOIN CustomerInfo cust ON pd.p_partkey = cust.c_custkey % 100
LEFT JOIN SupplierCTE scte ON pd.p_partkey % 10 = scte.s_suppkey % 10
LEFT JOIN DenseRankedOrders dro ON pd.p_partkey = dro.o_orderkey % 50
WHERE pd.total_cost IS NOT NULL 
AND pd.p_retailprice > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
ORDER BY pd.p_partkey, supplier_level DESC, dro.revenue_rank;
