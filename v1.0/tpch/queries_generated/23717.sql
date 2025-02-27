WITH RECURSIVE Region_Supplier AS (
    SELECT s.s_suppkey, s.s_name, n.n_nationkey, n.n_name, r.r_regionkey, r.r_name 
    FROM supplier s 
    INNER JOIN nation n ON s.s_nationkey = n.n_nationkey 
    INNER JOIN region r ON n.n_regionkey = r.r_regionkey 
    WHERE r.r_name LIKE 'A%' AND s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, n.n_nationkey, n.n_name, r.r_regionkey, r.r_name 
    FROM Region_Supplier rs 
    JOIN supplier s ON s.s_nationkey = rs.n_nationkey 
    JOIN nation n ON s.s_nationkey = n.n_nationkey 
    JOIN region r ON n.n_regionkey = r.r_regionkey 
    WHERE s.s_acctbal < (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
),
Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS OrderRank 
    FROM customer c 
    JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderstatus = 'O' 
),
High_Value_Orders AS (
    SELECT cust.c_custkey, cust.c_name, SUM(orders.o_totalprice) AS total_spent 
    FROM Customer_Orders orders 
    JOIN customer cust ON orders.c_custkey = cust.c_custkey
    WHERE orders.OrderRank <= 5 
    GROUP BY cust.c_custkey, cust.c_name 
    HAVING SUM(orders.o_totalprice) > 10000
)
SELECT rs.s_name, 
       COUNT(DISTINCT orders.o_orderkey) AS total_orders, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
       CASE 
           WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) IS NULL THEN 'No Revenue'
           ELSE CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS VARCHAR(20))
       END AS revenue_string,
       'Region: ' || rs.r_name AS region_info 
FROM Region_Supplier rs 
LEFT JOIN partsupp ps ON ps.ps_suppkey = rs.s_suppkey 
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey 
LEFT JOIN Customer_Orders o ON l.l_orderkey = o.o_orderkey 
JOIN High_Value_Orders hv ON o.c_custkey = hv.c_custkey 
WHERE l.returnflag = 'N' 
AND l.l_shipdate >= '2023-01-01' 
GROUP BY rs.s_name, rs.r_name 
HAVING total_orders > 0
ORDER BY total_revenue DESC, rs.s_name ASC NULLS LAST;
