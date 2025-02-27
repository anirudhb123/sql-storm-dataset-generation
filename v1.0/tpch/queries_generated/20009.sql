WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS level
    FROM nation
    WHERE n_nationkey = (SELECT MIN(n_nationkey) FROM nation)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
suppliers_with_comments AS (
    SELECT s.s_suppkey, s.s_name, s.s_comment, 
           CASE 
               WHEN s.s_comment IS NULL THEN 'No Comment' 
               ELSE s.s_comment 
           END AS comment_status
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
last_ordered_item AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_extendedprice, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
),
orders_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price, 
           COUNT(DISTINCT l.l_partkey) AS total_items
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O' AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
customer_with_rank AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank_acctbal
    FROM customer c
    WHERE c.c_mktsegment = 'BUILDING'
)
SELECT p.p_name, ps.ps_supplycost, 
       CASE 
           WHEN total_price IS NULL THEN 'No Orders' 
           ELSE total_price::varchar 
       END AS order_value,
       CASE
           WHEN sw.comment_status = 'No Comment' THEN 'Supplier has no comments'
           ELSE sw.comment_status
       END AS supplier_comments,
       (SELECT COUNT(*) FROM nation_hierarchy nh WHERE nh.level <= 2) AS nation_levels,
       ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS type_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN suppliers_with_comments sw ON ps.ps_suppkey = sw.s_suppkey
LEFT JOIN orders_summary os ON os.o_orderkey = (SELECT MAX(o_orderkey) FROM orders)
LEFT JOIN customer_with_rank cr ON cr.c_custkey = (SELECT MIN(c_custkey) FROM customer)
WHERE ps.ps_availqty > (
    SELECT COALESCE(MAX(l.l_quantity), 0) 
    FROM lineitem l 
    WHERE l.l_returnflag = 'R'
) AND p.p_retailprice BETWEEN 10.00 AND 100.00
ORDER BY p.p_name, p.p_retailprice DESC;
