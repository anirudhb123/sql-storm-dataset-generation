
WITH RECURSIVE ordered_nations AS (
    SELECT n.n_nationkey, n.n_name, r.r_name, 
           ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS nation_rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
high_value_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, c.c_name, 
           ROW_NUMBER() OVER (PARTITION BY c.c_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'F'
),
part_supply_details AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
part_retail_details AS (
    SELECT p.p_partkey, 
           COALESCE(MAX(p.p_retailprice), 0) AS max_price,
           COUNT(p.p_partkey) AS part_count
    FROM part p
    GROUP BY p.p_partkey
),
detailed_orders AS (
    SELECT o.o_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           COUNT(DISTINCT l.l_partkey) AS item_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
)
SELECT 
    rn.n_name AS nation_name,
    COALESCE(hvo.o_orderkey, -1) AS order_key,
    COALESCE(pd.max_price, 0) AS max_retail_price,
    pd.part_count AS part_count,
    COALESCE(d.net_revenue, 0) AS total_revenue,
    d.item_count AS total_items,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_returnflag = 'R') AS total_returns,
    (SELECT SUM(psd.total_cost) 
     FROM part_supply_details psd 
     JOIN part p ON psd.ps_partkey = p.p_partkey
     WHERE p.p_size BETWEEN 5 AND 20) AS total_part_supply_cost
FROM ordered_nations rn
LEFT JOIN high_value_orders hvo ON rn.n_nationkey = (SELECT c.c_nationkey FROM customer c 
                                                      WHERE c.c_name = hvo.c_name 
                                                      LIMIT 1)
LEFT JOIN part_retail_details pd ON pd.p_partkey = hvo.o_orderkey 
LEFT JOIN detailed_orders d ON d.o_orderkey = hvo.o_orderkey
WHERE rn.nation_rank = 1 AND (hvo.order_rank IS NULL OR hvo.order_rank <= 5)
ORDER BY rn.n_name, total_revenue DESC;
