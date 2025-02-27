WITH RECURSIVE CTE_Supplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, cs.level + 1
    FROM supplier s
    JOIN CTE_Supplier cs ON s.s_nationkey = cs.s_nationkey
    WHERE s.s_acctbal > cs.s_acctbal
),
Latest_Orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
),
Supplier_Part AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           p.p_name, p.p_brand, p.p_retailprice,
           CASE 
               WHEN ps.ps_supplycost > AVG(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey)
               THEN 'High Cost'
               ELSE 'Standard Cost'
           END AS cost_category
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
Customer_Orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
),
Max_Orders AS (
    SELECT total_orders, total_spent,
           RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM Customer_Orders
)
SELECT n.n_name AS nation_name, 
       r.r_name AS region_name, 
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(m.total_spent) AS max_spent,
       COALESCE(MAX(m.rank), 0) AS max_rank,
       GROUP_CONCAT(DISTINCT p.p_name ORDER BY p.p_name SEPARATOR ', ') AS product_names
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN Supplier_Part sp ON l.l_partkey = sp.ps_partkey
LEFT JOIN Max_Orders m ON c.c_custkey = m.c_custkey
WHERE l.l_returnflag = 'N'
GROUP BY n.n_name, r.r_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY total_revenue DESC
LIMIT 10;
