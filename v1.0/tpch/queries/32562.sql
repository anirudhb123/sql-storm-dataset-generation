WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_suppkey <> sh.s_suppkey AND s.s_acctbal > 5000
),
PartDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ps.ps_availqty, ps.ps_supplycost, 
           (ps.ps_availqty * p.p_retailprice) AS potential_revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE p.p_size BETWEEN 10 AND 20
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_mktsegment = 'Furniture'
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
)
SELECT rh.r_name, 
       SUM(pd.potential_revenue) AS total_revenue,
       AVG(co.total_spent) AS avg_spent_per_customer,
       MAX(co.order_count) AS max_orders_per_customer,
       CASE 
           WHEN SUM(pd.potential_revenue) IS NULL THEN 'No Revenue'
           ELSE 'Revenue Available'
       END AS revenue_status
FROM region rh
LEFT JOIN nation n ON rh.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN PartDetails pd ON s.s_suppkey = pd.ps_availqty
LEFT JOIN CustomerOrders co ON s.s_nationkey = co.c_custkey
WHERE rh.r_name LIKE 'S%' 
GROUP BY rh.r_name
HAVING SUM(pd.potential_revenue) > 0
ORDER BY total_revenue DESC
LIMIT 10;
