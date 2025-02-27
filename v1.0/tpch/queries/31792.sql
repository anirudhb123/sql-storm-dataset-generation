WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_nationkey = (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
    
    UNION ALL
    
    SELECT ps.ps_suppkey, sup.s_name, sup.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN supplier sup ON ps.ps_suppkey = sup.s_suppkey
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSales AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedSales AS (
    SELECT p_name, total_sales,
           RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM PartSales
)
SELECT r.r_name, 
       COALESCE(SUM(cs.total_spent), 0) AS total_customer_spend,
       COUNT(DISTINCT sh.s_suppkey) AS total_suppliers,
       COUNT(DISTINCT rs.p_name) AS total_top_products
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN CustomerOrders cs ON c.c_custkey = cs.c_custkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN RankedSales rs ON rs.sales_rank <= 10
GROUP BY r.r_name
ORDER BY total_customer_spend DESC, total_suppliers DESC;
