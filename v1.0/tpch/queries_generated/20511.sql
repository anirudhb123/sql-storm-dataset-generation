WITH Recursive_CTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
Aggregated_Suppliers AS (
    SELECT r.r_regionkey, r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(s.s_acctbal) AS total_acctbal
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_regionkey, r.r_name
),
Order_Analytics AS (
    SELECT o.o_orderkey, o.o_orderstatus, o.o_totalprice, 
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
LineItem_Analysis AS (
    SELECT l.l_orderkey, l.l_quantity, l.l_discount, 
           l.l_extendedprice * (1 - l.l_discount) AS discounted_price,
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned'
               ELSE 'Not Returned'
           END AS return_status
    FROM lineitem l
)
SELECT 
    r.r_name AS region_name,
    COALESCE(a.supplier_count, 0) AS active_suppliers,
    COALESCE(a.total_acctbal, 0.00) AS total_account_balance,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.discounted_price) AS total_discounted_sales,
    COUNT(DISTINCT ra.s_suppkey) AS top_suppliers,
    AVG(o.price_rank) AS avg_order_price_rank
FROM Aggregated_Suppliers a
FULL OUTER JOIN Recursive_CTE ra ON a.r_regionkey = ra.s_suppkey 
LEFT JOIN Order_Analytics o ON ra.rn = 1 AND o.o_orderstatus = 'O'
LEFT JOIN LineItem_Analysis l ON o.o_orderkey = l.l_orderkey
GROUP BY r.r_regionkey, r.r_name
HAVING SUM(l.l_quantity) > 100 OR SUM(l.l_discount) IS NULL
ORDER BY region_name;
