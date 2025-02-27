WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
TotalOrderValue AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
FilteredOrders AS (
    SELECT o.*, tv.total_value
    FROM orders o
    LEFT JOIN TotalOrderValue tv ON o.o_orderkey = tv.o_orderkey
    WHERE o.o_orderstatus = 'O' 
      AND (tv.total_value IS NULL OR tv.total_value > 10000)
),
NationStatistics AS (
    SELECT n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
),
PartStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS availability_count
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING COUNT(ps.ps_suppkey) > 0
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, 
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    ch.n_name AS Nation,
    ps.p_name AS Part_Name,
    cs.c_name AS Customer_Name,
    coalesce(t.total_value, 0) AS Order_Total_Value,
    p.availability_count AS Part_Availability,
    sh.level AS Supplier_Hierarchy_Level
FROM CustomerOrderSummary cs
JOIN PartStatistics p ON cs.order_count > 5
JOIN Region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name LIKE '%India%') 
LEFT JOIN FilteredOrders t ON cs.order_count = (SELECT COUNT(*) FROM orders WHERE o_custkey = cs.c_custkey)
CROSS JOIN NationStatistics ch
JOIN SupplierHierarchy sh ON sh.s_nationkey = cs.c_nationkey
ORDER BY Order_Total_Value DESC, Part_Availability ASC;
