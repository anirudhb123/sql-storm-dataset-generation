WITH Recursive_Suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT ps.ps_suppkey, s.s_name, s.s_acctbal, level + 1
    FROM partsupp ps
    JOIN Recursive_Suppliers s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND level < 5
),
Order_Summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate < CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey
),
Customer_Rank AS (
    SELECT c.c_custkey, c.c_name,
           DENSE_RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS cust_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 2
),
Region_Nation AS (
    SELECT r.r_name, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name, n.n_name
    HAVING COUNT(s.s_suppkey) > 0
)
SELECT r.n_name, r.r_name AS region_name, COALESCE(rs.level, 0) AS supplier_hierarchy,
       SUM(os.total_revenue) AS total_sales,
       COUNT(cr.cust_rank) AS customer_count
FROM Region_Nation r
LEFT JOIN Recursive_Suppliers rs ON r.supplier_count = rs.s_suppkey
LEFT JOIN Order_Summary os ON os.o_orderkey IN 
    (SELECT o.o_orderkey FROM orders o 
     WHERE o.o_shippriority >= 10 AND o.o_orderstatus = 'F')
LEFT JOIN Customer_Rank cr ON cr.c_custkey IN 
    (SELECT DISTINCT c.c_custkey FROM customer c WHERE c.c_acctbal IS NOT NULL)
GROUP BY r.r_name, r.n_name, COALESCE(rs.level, 0)
HAVING COUNT(DISTINCT cr.cust_rank) > 1 
   OR SUM(os.total_revenue) BETWEEN 10000 AND 50000
ORDER BY total_sales DESC, r.n_name ASC;
