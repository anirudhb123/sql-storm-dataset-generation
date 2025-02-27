WITH supplier_totals AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
order_summary AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank,
           COUNT(l.l_orderkey) OVER (PARTITION BY o.o_orderkey) AS item_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
),
best_sellers AS (
    SELECT l.l_partkey, SUM(l.l_quantity) AS total_quantity
    FROM lineitem l
    GROUP BY l.l_partkey
    HAVING SUM(l.l_quantity) > (SELECT AVG(total_quantity) FROM (
        SELECT SUM(l.l_quantity) AS total_quantity
        FROM lineitem l
        GROUP BY l.l_partkey
    ) AS avg_totals)
)
SELECT p.p_name, p.p_brand, p.p_retailprice, s.s_name, st.total_supplycost, os.o_totalprice, os.o_orderdate, os.order_rank, os.item_count
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN supplier_totals st ON s.s_suppkey = st.s_suppkey
LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
WHERE st.total_supplycost > 10000
  AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
  AND EXISTS (SELECT 1 FROM best_sellers bs WHERE bs.l_partkey = p.p_partkey)
ORDER BY p.p_retailprice DESC, os.o_orderdate DESC NULLS LAST;
