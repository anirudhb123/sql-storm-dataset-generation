WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size,
           p_retailprice, p_comment,
           CAST(NULL AS INTEGER) AS parent_partkey
    FROM part
    WHERE p_size > 0
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size,
           p.p_retailprice, p.p_comment,
           ph.p_partkey
    FROM part p
    JOIN part_hierarchy ph ON p.p_size = ph.p_size AND ph.parent_partkey IS NULL
    WHERE p.p_partkey <> ph.p_partkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS supplier_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
customer_stats AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent,
           STRING_AGG(DISTINCT o.o_comment, ', ') AS order_comments
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
lineitem_summary AS (
    SELECT l.l_orderkey, SUM(l.l_quantity) AS total_quantity, 
           AVG(l.l_extendedprice) AS avg_price_per_item,
           COUNT(CASE WHEN l.l_discount > 0 THEN 1 END) AS discount_items
    FROM lineitem l
    GROUP BY l.l_orderkey
),
final_report AS (
    SELECT 
        pi.p_partkey, pi.p_name, si.s_name, cs.order_count,
        cs.total_spent,
        ls.total_quantity, ls.avg_price_per_item, ls.discount_items,
        ROW_NUMBER() OVER (PARTITION BY pi.p_brand ORDER BY cs.total_spent DESC) AS brand_rank
    FROM part_hierarchy pi
    LEFT JOIN supplier_info si ON pi.p_partkey = si.s_suppkey
    LEFT JOIN customer_stats cs ON cs.order_count > 5
    LEFT JOIN lineitem_summary ls ON cs.order_count = ls.l_orderkey
    WHERE pi.p_retailprice BETWEEN 100 AND 500 
    AND (si.s_acctbal IS NULL OR si.s_acctbal >= cs.total_spent)
)
SELECT f.*, 
       COALESCE(f.total_quantity / NULLIF(f.avg_price_per_item, 0), -1) AS quantity_to_price_ratio,
       CASE 
           WHEN f.discount_items > 0 THEN 'Discounted' 
           ELSE 'Regular' 
       END AS item_type_desc
FROM final_report f
ORDER BY f.brand_rank, f.total_spent DESC;
