
WITH RECURSIVE price_comparison AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_availqty
                       FROM partsupp ps
                       WHERE ps.ps_supplycost > 100
                       AND ps.ps_partkey IN (SELECT DISTINCT l.l_partkey
                                             FROM lineitem l
                                             WHERE l.l_returnflag = 'R'))
),
nation_suppliers AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supp_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count,
           MAX(o.o_totalprice) AS max_totalprice,
           SUM(CASE WHEN o.o_orderstatus = 'F' THEN o.o_totalprice ELSE 0 END) AS finalized_total
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL
    GROUP BY c.c_custkey, c.c_name
)
SELECT nc.n_name, cs.c_name, cs.order_count, cs.max_totalprice, pc.p_name, pc.p_retailprice,
       (CASE WHEN pc.p_retailprice IS NULL THEN 'No Price' 
             WHEN pc.price_rank <= 3 THEN 'Top Price'
             ELSE 'Other Price' END) AS price_category
FROM nation_suppliers nc
FULL OUTER JOIN customer_orders cs ON nc.supp_count = 
    (SELECT COUNT(*)
     FROM supplier s
     WHERE s.s_nationkey = nc.n_nationkey AND s.s_acctbal > 0)
LEFT JOIN price_comparison pc ON pc.price_rank = 1
WHERE cs.finalized_total > 0
ORDER BY nc.n_name, cs.c_name, pc.p_retailprice DESC
LIMIT 5 OFFSET 10;
