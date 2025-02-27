WITH RECURSIVE nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation AS n
    JOIN supplier AS s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier AS s1 WHERE s1.s_nationkey = n.n_nationkey)
    
    UNION ALL
    
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation_supplier AS ns
    JOIN supplier AS s ON ns.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > ns.s_acctbal
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders AS o
    WHERE o.o_orderstatus = 'O'
),
high_value_order_lines AS (
    SELECT li.l_orderkey, SUM(li.l_extendedprice * (1 - li.l_discount)) AS order_value
    FROM lineitem AS li
    JOIN ranked_orders AS ro ON li.l_orderkey = ro.o_orderkey
    WHERE ro.order_rank <= 10
    GROUP BY li.l_orderkey
)
SELECT p.p_partkey, p.p_name, 
       COALESCE(SUM(h.order_value), 0) AS total_value,
       r.r_name AS region_name,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count
FROM part AS p
LEFT JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier AS s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation AS n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region AS r ON n.n_regionkey = r.r_regionkey
LEFT JOIN high_value_order_lines AS h ON h.l_orderkey = ps.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p1.p_retailprice) FROM part AS p1 WHERE p1.p_size IS NOT NULL)
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY total_value DESC
LIMIT 100;
