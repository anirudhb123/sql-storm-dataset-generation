WITH supplier_data AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
),
high_value_suppliers AS (
    SELECT DISTINCT s.s_suppkey, s.s_name
    FROM supplier s
    JOIN supplier_data sd ON s.s_suppkey = sd.s_suppkey
    WHERE sd.rank <= 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_totalprice,
           DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer WHERE c_mktsegment = 'BUILDING')
),
lineitem_summary AS (
    SELECT l.l_orderkey,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
           COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT p.p_partkey, p.p_name, p.p_mfgr, 
       CASE 
           WHEN ls.total_price > 100000 THEN 'High'
           WHEN ls.total_price BETWEEN 50000 AND 100000 THEN 'Medium'
           ELSE 'Low'
       END AS price_category,
       c.c_name,
       (SELECT COUNT(*) FROM high_value_suppliers hvs 
        WHERE hvs.s_suppkey IN 
          (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)) AS supplier_count,
       COALESCE(cs.order_rank, NULL) AS highest_order_rank
FROM part p
LEFT JOIN lineitem_summary ls ON ls.l_orderkey = (SELECT MAX(o.o_orderkey)
                                                  FROM orders o
                                                  WHERE o.o_orderkey IN (SELECT l.l_orderkey 
                                                                          FROM lineitem l
                                                                          WHERE l.l_partkey = p.p_partkey))
LEFT JOIN customer_orders cs ON cs.o_orderkey = ls.l_orderkey
WHERE p.p_size < (
    SELECT AVG(p_size) FROM part p_sub WHERE p_sub.p_type = p.p_type
)
ORDER BY price_category DESC, p.p_partkey;
