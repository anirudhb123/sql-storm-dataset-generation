WITH RECURSIVE part_supplier AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rank_cost 
    FROM partsupp ps
), 
customer_order AS (
    SELECT c.c_custkey, 
           c.c_name, 
           COUNT(o.o_orderkey) as order_count, 
           DENSE_RANK() OVER (ORDER BY COUNT(o.o_orderkey) DESC) as order_rank 
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey 
    WHERE o.o_orderstatus IN ('F', 'O') OR o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31' 
    GROUP BY c.c_custkey, c.c_name
), 
lineitem_stats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
           COUNT(*) FILTER (WHERE l.l_shipdate IS NOT NULL) AS shipped_items,
           COUNT(*) FILTER (WHERE l.l_returnflag = 'R') AS returned_items
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT p.p_name, 
       s.s_name, 
       COALESCE(o.order_count, 0) AS customer_orders,
       pl.total_revenue AS total_order_value,
       ps.rank_cost AS supplier_price_rank
FROM part p 
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey 
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
LEFT JOIN customer_order o ON s.s_nationkey = (SELECT n.n_nationkey 
                                                   FROM nation n 
                                                   WHERE n.n_name LIKE CONCAT('%', 'Country', '%')) 
LEFT JOIN lineitem_stats pl ON pl.l_orderkey IN (SELECT o.o_orderkey 
                                                FROM orders o 
                                                WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 50000)
WHERE (ps.rank_cost <= 5 OR pl.total_revenue >= 100000) 
AND (s.s_acctbal IS NOT NULL AND s.s_acctbal > 0)
ORDER BY total_order_value DESC, customer_orders ASC;
