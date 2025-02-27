WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 10
),
filtered_parts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           CASE
               WHEN p.p_retailprice > 100 THEN 'Expensive'
               WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderate'
               ELSE 'Cheap'
           END AS price_category,
           ROW_NUMBER() OVER (PARTITION BY 
               CASE 
                   WHEN p.p_size IN (1, 2) THEN 'Small'
                   WHEN p.p_size BETWEEN 3 AND 5 THEN 'Medium'
                   ELSE 'Large'
               END 
           ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
customer_orders AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
    GROUP BY c.c_custkey, c.c_name
),
nation_part AS (
    SELECT n.n_name, 
           np.p_partkey, 
           np.product_count
    FROM (SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT ps.ps_partkey) AS product_count
          FROM nation n
          JOIN supplier s ON n.n_nationkey = s.s_nationkey
          JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
          GROUP BY n.n_nationkey, n.n_name) np
),
final_results AS (
    SELECT p.p_name, 
           p.price_category, 
           cu.total_spent, 
           nh.n_name,
           sh.level AS supplier_level,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM filtered_parts p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN customer_orders cu ON cu.total_spent IS NOT NULL
    JOIN nation_part nh ON nh.p_partkey = p.p_partkey
    LEFT JOIN supplier_hierarchy sh ON sh.s_nationkey = nh.n_nationkey
    WHERE l.l_returnflag = 'N'
    GROUP BY p.p_name, p.price_category, cu.total_spent, nh.n_name, sh.level
    HAVING SUM(l.l_extendedprice) IS NOT NULL
)
SELECT f.*, 
       (CASE
           WHEN f.total_spent IS NULL THEN 'No Orders'
           WHEN f.total_spent > 1000 THEN 'High Roller'
           ELSE 'Regular'
       END) AS customer_category
FROM final_results f
ORDER BY f.total_line_price DESC, f.price_category;
