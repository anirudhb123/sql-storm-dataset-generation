WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_nationkey, s_suppkey, 
           s_name, 
           (s_acctbal + COALESCE(NULLIF(LAG(s_acctbal) OVER (PARTITION BY s_nationkey ORDER BY s_suppkey) - 100, 0), 0)) AS adjusted_acctbal,
           0 AS depth 
    FROM supplier
    UNION ALL
    SELECT sh.s_nationkey, sh.s_suppkey, 
           sh.s_name, 
           (sh.s_acctbal + COALESCE(NULLIF(LAG(sh.s_acctbal) OVER (PARTITION BY sh.s_nationkey ORDER BY sh.s_suppkey) - 200, 0), 0)) AS adjusted_acctbal,
           sh.depth + 1 
    FROM supplier_hierarchy sh 
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.depth < 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, 
           o.o_totalprice, o.o_orderstatus,
           ROW_NUMBER() OVER (PARTITION BY c.custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus IN ('O', 'F') 
),
part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           CASE 
               WHEN p.p_retailprice < 100 THEN 'low'
               WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'medium'
               ELSE 'high'
           END AS price_category,
           COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
)
SELECT c.c_name, 
       SUM(CASE WHEN co.o_orderstatus = 'O' THEN co.o_totalprice ELSE 0 END) AS total_open_orders,
       MAX(pd.price_category) AS max_price_category,
       COUNT(DISTINCT pd.p_partkey) AS unique_parts_supplied,
       s.supp_name,
       sh.adjusted_acctbal
FROM customer_orders co
JOIN customer c ON co.c_custkey = c.c_custkey
LEFT JOIN part_details pd ON pd.supplier_count > 0
JOIN supplier_hierarchy sh ON sh.s_nationkey = c.c_nationkey
LEFT JOIN (
    SELECT s.s_suppkey, s.s_name AS supp_name, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
) s ON s.rank = 1
WHERE co.rn = 1 
GROUP BY c.c_name, s.supp_name, sh.adjusted_acctbal
HAVING MAX(co.o_totalprice) > 1000 
   AND COUNT(DISTINCT pd.p_partkey) < 10
ORDER BY total_open_orders DESC, c.c_name;
