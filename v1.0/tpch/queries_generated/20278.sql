WITH RECURSIVE CustomerCTE AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey, c_mktsegment, 1 AS depth
    FROM customer
    WHERE c_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey, c.c_mktsegment, depth + 1
    FROM customer c
    JOIN CustomerCTE cc ON c.c_nationkey = cc.c_nationkey
    WHERE c.c_acctbal IS NOT NULL AND cc.depth < 5
),
TotalSales AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey
),
RegionSummary AS (
    SELECT r.r_name, COUNT(DISTINCT n.n_nationkey) AS nation_count, SUM(s.s_acctbal) AS total_acct_balance
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
RankedSales AS (
    SELECT c.c_custkey, SUM(ts.total) AS customer_total_sales, 
           RANK() OVER (ORDER BY SUM(ts.total) DESC) AS sales_rank
    FROM CustomerCTE c
    LEFT JOIN TotalSales ts ON c.c_custkey = ts.o_orderkey
    GROUP BY c.c_custkey
)
SELECT 
    r.r_name,
    rs.customer_total_sales,
    COALESCE(cc.depth, 0) AS customer_depth,
    rs.sales_rank,
    CASE 
        WHEN rs.customer_total_sales IS NULL THEN 'No Sales'
        WHEN rs.customer_total_sales > (SELECT AVG(customer_total_sales) FROM RankedSales) 
        THEN 'Above Average Sales'
        ELSE 'Below Average Sales'
    END AS sales_category
FROM RegionSummary r
LEFT JOIN RankedSales rs ON r.nation_count = COALESCE((SELECT COUNT(DISTINCT c_nationkey) FROM customer WHERE c_acctbal > 100), 0)
LEFT JOIN CustomerCTE cc ON cc.c_nationkey = r.r_regionkey
WHERE r.total_acct_balance > (SELECT AVG(s_acctbal) FROM supplier) 
    AND r.nation_count IS NOT NULL
ORDER BY r.r_name, rs.sales_rank NULLS LAST;
