WITH RECURSIVE cte_supplier AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    INNER JOIN cte_supplier cs ON s.s_acctbal < cs.s_acctbal
    WHERE s.s_suppkey != cs.s_suppkey
), ranked_orders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, 
           RANK() OVER (PARTITION BY o_orderstatus ORDER BY o_totalprice DESC) AS price_rank
    FROM orders
), lineitem_summary AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price
    FROM lineitem
    GROUP BY l_orderkey
), supplier_part AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
), nation_supplier AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ns.n_name, ns.supplier_count, SUM(l.total_price) AS total_lineitem_price, 
       COALESCE(SUM(sp.total_supply_cost), 0) AS total_supply_cost,
       COUNT(DISTINCT ro.o_orderkey) AS total_orders
FROM nation_supplier ns
LEFT JOIN lineitem_summary l ON ns.n_nationkey = (
    SELECT n.n_nationkey
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE li.l_extendedprice > 100
)
LEFT JOIN ranked_orders ro ON ro.o_orderkey IN (
    SELECT l_orderkey
    FROM lineitem
    WHERE l_returnflag = 'R'
)
LEFT JOIN supplier_part sp ON sp.ps_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal) 
        FROM supplier
    )
)
GROUP BY ns.n_name, ns.supplier_count
HAVING COUNT(DISTINCT ro.o_orderkey) > 5
ORDER BY DISTINCT ns.n_name;
