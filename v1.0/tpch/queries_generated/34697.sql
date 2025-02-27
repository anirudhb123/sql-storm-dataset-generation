WITH RECURSIVE RegionHierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 1 AS depth
    FROM region
    WHERE r_name LIKE 'S%'
    
    UNION ALL
    
    SELECT n.n_regionkey, r.r_name, r.r_comment, depth + 1
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN RegionHierarchy rh ON n.n_nationkey = rh.r_regionkey
),
CustomerOrderTotals AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierPartStats AS (
    SELECT ps.ps_partkey,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost,
           COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey
),
OutstandingOrders AS (
    SELECT o.o_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_orderkey DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate > CURRENT_DATE - INTERVAL '30 days'
    GROUP BY o.o_orderkey
    HAVING COUNT(*) > 1
)

SELECT rh.r_name AS Region_Name,
       COUNT(DISTINCT c.c_custkey) AS Customers_Count,
       AVG(ct.total_spent) AS Avg_Spent_Per_Customer,
       SUM(ps.total_available) AS Total_Available_Parts,
       SUM(os.total_order_value) AS Recent_Order_Value
FROM RegionHierarchy rh
LEFT JOIN customer c ON rh.r_regionkey = c.c_nationkey
LEFT JOIN CustomerOrderTotals ct ON c.c_custkey = ct.c_custkey
LEFT JOIN SupplierPartStats ps ON ps.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey))
LEFT JOIN OutstandingOrders os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
GROUP BY rh.r_name
HAVING SUM(ps.total_available) IS NOT NULL AND COUNT(c.c_custkey) > 0
ORDER BY Region_Name;
