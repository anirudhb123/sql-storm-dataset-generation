WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 3 AND s.s_acctbal >= sh.s_acctbal
),
FilteredRegions AS (
    SELECT r.r_regionkey, r.r_name, COUNT(n.n_nationkey) AS nation_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_regionkey, r.r_name
    HAVING COUNT(n.n_nationkey) > 2
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_custkey
    HAVING total_revenue > 10000
),
CustomerStats AS (
    SELECT c.c_custkey, 
           COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    sh.s_name AS Supplier_Name,
    r.r_name AS Region_Name,
    cs.order_count AS Customer_Order_Count,
    cs.total_spent AS Total_Spent_By_Customer,
    cs.avg_order_value AS Avg_Order_Value,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE (l.l_returnflag = 'R' AND l.l_linestatus = 'O')) AS Returned_Orders,
    COUNT(DISTINCT o.o_orderkey) FILTER (WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year') AS Recent_Orders
FROM SupplierHierarchy sh
JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN FilteredRegions fr ON fr.r_regionkey = sh.s_nationkey
JOIN CustomerStats cs ON cs.c_custkey = (
    SELECT c.c_custkey 
    FROM customer c 
    WHERE c.c_nationkey = sh.s_nationkey 
    ORDER BY NULLIF(c.c_acctbal, 0) DESC 
    LIMIT 1 
)
JOIN orders o ON o.o_custkey = cs.c_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE p.p_retailprice > (
    SELECT AVG(p2.p_retailprice) 
    FROM part p2 
    WHERE p2.p_size BETWEEN 1 AND 10
) 
GROUP BY sh.s_name, r.r_name, cs.order_count, cs.total_spent, cs.avg_order_value
HAVING SUM(l.l_extendedprice) IS NOT NULL
ORDER BY cs.total_spent DESC, r.r_name ASC;
