WITH RECURSIVE part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost, 
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) as rn
    FROM partsupp ps
), ranked_suppliers AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
        s.s_name, s.s_acctbal, ss.ps_supplycost, 
        CASE
            WHEN p.p_size IS NULL THEN 'Unknown size'
            WHEN p.p_size > 20 THEN 'Large'
            ELSE 'Small/Medium'
        END AS size_category
    FROM part p
    JOIN part_supplier ss ON p.p_partkey = ss.ps_partkey
    JOIN supplier s ON ss.ps_suppkey = s.s_suppkey
    WHERE ss.rn = 1 
), total_orders AS (
    SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_custkey
), nations_regions AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
), customer_data AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
        COALESCE(nr.n_name, 'No Nation') AS nation_name
    FROM customer c
    LEFT JOIN nations_regions nr ON c.c_nationkey = nr.n_nationkey
), order_summary AS (
    SELECT c.custkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer_data c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.custkey
)
SELECT rs.p_name, rs.size_category, r.r_name AS region, 
       COUNT(co.custkey) AS customer_count, 
       AVG(co.total_spent) AS avg_spent,
       MAX(o.order_count) AS max_orders,
       MIN(o.total_spent) AS min_spent
FROM ranked_suppliers rs
LEFT JOIN countries co ON co.region = rs.p_name 
LEFT JOIN customer_data c ON c.c_custkey = co.customer_id
JOIN nations_regions r ON c.nation_name = r.n_name
LEFT JOIN order_summary o ON c.c_custkey = o.custkey
WHERE rs.p_retailprice BETWEEN 
      (SELECT AVG(p_retailprice) FROM part) * 0.9 AND 
      (SELECT AVG(p_retailprice) FROM part) * 1.1
GROUP BY rs.p_name, rs.size_category, r.r_name
HAVING COUNT(co.custkey) > 10 
   AND AVG(co.total_spent) > 1000
ORDER BY region, customer_count DESC;
