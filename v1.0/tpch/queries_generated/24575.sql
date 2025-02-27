WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, CONCAT(sh.s_name, ' -> ', s.s_name), s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 10
),
RegionSupply AS (
    SELECT r.r_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name
),
CustomerOrderCount AS (
    SELECT c.c_custkey,
           c.c_name,
           COUNT(o.o_orderkey) AS order_count,
           SUM(CASE WHEN o.o_orderstatus = 'O' THEN o.o_totalprice ELSE 0 END) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT r.r_name AS Region,
       COALESCE(rs.total_cost, 0) AS Region_Total_Cost,
       COALESCE(cs.order_count, 0) AS Customer_Order_Count,
       sh.level AS Supplier_Hierarchy_Level,
       ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(rs.total_cost, 0) DESC) AS region_rank
FROM RegionSupply rs
FULL OUTER JOIN CustomerOrderCount cs ON cs.total_spent > 1000
LEFT JOIN SupplierHierarchy sh ON sh.s_suppkey = cs.c_custkey
LEFT JOIN region r ON r.r_name = 'ASIA'
WHERE sh.s_acctbal < 5000 OR (sh.s_name IS NULL AND r.r_regionkey IS NOT NULL)
ORDER BY Region, Region_Total_Cost DESC, Customer_Order_Count
LIMIT 10;

