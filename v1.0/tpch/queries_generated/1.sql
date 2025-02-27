WITH RECURSIVE SuppliersCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, level + 1
    FROM supplier s
    JOIN SuppliersCTE cte ON s.s_nationkey = cte.s_nationkey
    WHERE s.s_acctbal < cte.s_acctbal
),
TotalOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY o.o_orderkey
),
RankedSales AS (
    SELECT ts.o_orderkey, ts.total_sales,
           RANK() OVER (ORDER BY ts.total_sales DESC) AS sales_rank
    FROM TotalOrders ts
)
SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    COALESCE(rn.r_name, 'Unknown') AS region_name,
    SUM(CASE WHEN ll.l_returnflag = 'R' THEN ll.l_quantity ELSE 0 END) AS total_returns,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    STRING_AGG(DISTINCT CONCAT(s.s_name, '(', s.s_acctbal, ')') ORDER BY s.s_acctbal DESC) AS supplier_info
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region rn ON n.n_regionkey = rn.r_regionkey
LEFT JOIN lineitem ll ON p.p_partkey = ll.l_partkey
LEFT JOIN RankedSales rs ON rs.o_orderkey = ll.l_orderkey
LEFT JOIN customer c ON rs.o_orderkey = c.c_custkey
WHERE p.p_retailprice > 20.00 
AND (rn.r_name IS NOT NULL OR p.p_comment IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, rn.r_name
HAVING SUM(ll.l_quantity) > 100
ORDER BY total_returns DESC, p.p_partkey ASC;
