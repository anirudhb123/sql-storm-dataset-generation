WITH RECURSIVE nation_summary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT ns.n_nationkey, ns.n_name, ns.supplier_count + 1
    FROM nation_summary ns
    JOIN supplier s ON ns.n_nationkey = s.s_nationkey
    WHERE ns.supplier_count < 10
),
ranked_orders AS (
    SELECT o.o_orderkey, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
),
part_supplier_details AS (
    SELECT p.p_partkey, p.p_name, sum(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY sum(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
total_sales AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales_value
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01'
    GROUP BY l.l_partkey
)
SELECT p.p_name, ps.total_supply_value, ts.total_sales_value,
       ts.total_sales_value - COALESCE(ps.total_supply_value, 0) AS profit,
       ns.n_name AS nation_name
FROM part p
LEFT JOIN part_supplier_details ps ON p.p_partkey = ps.p_partkey AND ps.supply_rank = 1
LEFT JOIN total_sales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN nation_summary ns ON ns.n_nationkey = (
    SELECT n.n_nationkey
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_suppkey IN (
        SELECT DISTINCT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey = p.p_partkey
    )
    LIMIT 1
)
WHERE (ts.total_sales_value IS NOT NULL OR ps.total_supply_value IS NOT NULL)
ORDER BY profit DESC, ts.total_sales_value DESC
LIMIT 10;
