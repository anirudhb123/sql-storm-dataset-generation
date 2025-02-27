WITH RECURSIVE RegionRank AS (
    SELECT r.r_regionkey, 
           r.r_name, 
           COALESCE(NULLIF(r.r_comment, ''), 'No comment') AS r_comment,
           DENSE_RANK() OVER (ORDER BY r.r_name) AS r_rank
    FROM region r
    WHERE r.r_regionkey IS NOT NULL
), 
SupplierSales AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * li.l_quantity) AS total_supply_cost,
           COUNT(DISTINCT o.o_orderkey) AS total_orders,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * li.l_quantity) DESC) AS row_num
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem li ON ps.ps_partkey = li.l_partkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY s.s_suppkey
), 
CustomerSummary AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           CASE 
               WHEN COUNT(DISTINCT o.o_orderkey) > 5 THEN 'Regular'
               ELSE 'Occasional'
           END AS customer_type
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT r.r_name AS region_name,
       COUNT(DISTINCT ss.s_suppkey) AS supplier_count,
       SUM(cs.total_spent) AS total_customer_spending,
       AVG(cs.order_count) FILTER (WHERE cs.customer_type = 'Regular') AS avg_regular_orders,
       MAX(CASE WHEN ss.row_num = 1 THEN ss.total_supply_cost ELSE NULL END) AS max_supply_cost_top_supplier
FROM RegionRank r
LEFT JOIN SupplierSales ss ON r.r_regionkey = ss.s_nationkey
FULL OUTER JOIN CustomerSummary cs ON r.r_regionkey = cs.c_custkey
WHERE r.r_rank BETWEEN 1 AND 3
  AND (cs.total_spent IS NOT NULL OR ss.total_orders > 0)
GROUP BY r.r_name
HAVING COUNT(DISTINCT ss.s_suppkey) > 2
   OR SUM(cs.total_spent) IS NOT NULL
ORDER BY r.r_name DESC;
