WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderdate, o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate) AS order_rank
    FROM orders
    WHERE o_orderdate >= '2022-01-01'
),
SupplierShare AS (
    SELECT ps.ps_partkey, s.s_nationkey, SUM(ps.ps_supplycost * l.l_quantity) AS total_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= DATEADD(month, -3, CURRENT_DATE)
    GROUP BY ps.ps_partkey, s.s_nationkey
),
CustomerOverview AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
RankedCustomers AS (
    SELECT c.*, 
           RANK() OVER (ORDER BY total_spent DESC) AS spend_rank
    FROM CustomerOverview c
)
SELECT rh.order_rank, rc.c_name, rc.total_spent, rc.order_count,
       COALESCE(ss.total_supplycost,0) AS total_supply_cost,
       CASE 
           WHEN rc.order_count > 5 THEN 'High'
           WHEN rc.order_count BETWEEN 3 AND 5 THEN 'Medium'
           ELSE 'Low'
       END AS order_frequency_category
FROM OrderHierarchy rh
JOIN RankedCustomers rc ON rh.o_custkey = rc.c_custkey
LEFT JOIN SupplierShare ss ON ss.ps_partkey = rh.o_orderkey
WHERE rc.spend_rank < 10 
      AND rh.o_orderdate IN (SELECT DISTINCT l_shipdate
                              FROM lineitem l
                              WHERE l_returnflag = 'R')
ORDER BY rc.total_spent DESC, rh.order_rank;
