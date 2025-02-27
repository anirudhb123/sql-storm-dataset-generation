WITH RECURSIVE Region_CTE AS (
    SELECT r_regionkey, r_name, r_comment
    FROM region
    WHERE r_regionkey = 1
    UNION ALL
    SELECT r.r_regionkey, r.r_name, r.r_comment
    FROM region r
    JOIN Region_CTE rc ON r.r_regionkey = rc.r_regionkey + 1
    WHERE r.r_regionkey <= 5
),
Filtered_Customers AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
    HAVING SUM(o.o_totalprice) > 1000
),
Part_Supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
Aggregated_Orders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
Nation_Supplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
Final_Output AS (
    SELECT DISTINCT c.c_name, rc.r_name, ns.n_name,
           COALESCE(fs.total_spent, 0) AS customer_spending,
           COALESCE(ps.total_cost, 0) AS supplier_cost,
           ao.revenue,
           CASE WHEN ao.rank = 1 THEN 'Top Order' ELSE 'Normal Order' END AS order_status
    FROM Filtered_Customers fs
    FULL OUTER JOIN Region_CTE rc ON rc.r_regionkey IS NOT NULL
    JOIN Nation_Supplier ns ON ns.n_nationkey = fs.c_nationkey
    LEFT JOIN Part_Supplier ps ON ps.ps_partkey IS NOT NULL
    LEFT JOIN Aggregated_Orders ao ON ao.o_orderkey IS NOT NULL
    WHERE (rc.r_name LIKE '%e%' OR rc.r_name IS NULL) AND fs.total_spent IS NOT NULL
)
SELECT f.*, 
       CONCAT(f.c_name, ' from ', f.r_name, ' in ', f.n_name) AS customer_info,
       CASE 
           WHEN f.customer_spending > 5000 THEN 'High Value Customer'
           WHEN f.customer_spending > 1000 THEN 'Medium Value Customer'
           ELSE 'Low Value Customer'
       END AS customer_category
FROM Final_Output f
ORDER BY f.customer_spending DESC NULLS LAST;
