WITH RECURSIVE nested_parts AS (
    SELECT p_partkey, p_name, p_retailprice, 1 AS nesting_level
    FROM part
    WHERE p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice > 100.00)
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_retailprice, np.nesting_level + 1
    FROM part p
    JOIN nested_parts np ON p.p_size = np.p_retailprice
    WHERE np.nesting_level < 5
),
supplier_avg_cost AS (
    SELECT ps.ps_suppkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_suppkey
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT cp.p_name, cp.p_retailprice, 
       FIRST_VALUE(s.s_name) OVER (PARTITION BY cp.nesting_level ORDER BY sc.avg_cost) AS top_supplier,
       ni.n_name AS nation_name,
       COALESCE(co.total_orders, 0) AS order_count,
       CASE
           WHEN co.total_spent > 1000 THEN 'High'
           WHEN co.total_spent BETWEEN 500 AND 1000 THEN 'Medium'
           ELSE 'Low'
       END AS spending_category
FROM nested_parts cp
LEFT JOIN supplier_avg_cost sc ON sc.avg_cost < cp.p_retailprice
LEFT JOIN nation_details ni ON ni.n_nationkey = (SELECT n.n_nationkey 
                                                  FROM supplier s 
                                                  WHERE s.s_suppkey = sc.ps_suppkey 
                                                  LIMIT 1)
LEFT JOIN customer_orders co ON co.c_custkey = (SELECT c.c_custkey 
                                                 FROM customer c 
                                                 WHERE c.c_nationkey = ni.n_nationkey 
                                                 ORDER BY c.c_acctbal DESC 
                                                 LIMIT 1)
WHERE cp.p_retailprice IS NOT NULL
  AND cp.nesting_level < 4
ORDER BY cp.p_retailprice DESC, cp.p_name;
