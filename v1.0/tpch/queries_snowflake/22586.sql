
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = (sh.s_suppkey + 1) 
    WHERE sh.level < 5 AND s.s_acctbal IS NOT NULL
),
aggregated_data AS (
    SELECT 
        p.p_partkey, 
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(COALESCE(s.s_acctbal, 0)) AS avg_acctbal
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey
),
ranked_parts AS (
    SELECT 
        ad.p_partkey,
        ad.supplier_count,
        ad.total_avail_qty,
        ad.avg_acctbal,
        RANK() OVER (ORDER BY ad.total_avail_qty DESC, ad.avg_acctbal ASC) AS part_rank
    FROM aggregated_data ad
)
SELECT 
    rp.p_partkey,
    CASE 
        WHEN rp.supplier_count IS NULL THEN 'No suppliers'
        ELSE CONCAT('Suppliers: ', rp.supplier_count) 
    END AS supplier_info,
    rp.total_avail_qty,
    rp.avg_acctbal,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderkey IN 
        (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
    ) AS related_order_count,
    (SELECT COUNT(*)
     FROM supplier_hierarchy sh
     WHERE sh.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = rp.p_partkey)
    ) AS related_supplier_count
FROM ranked_parts rp
WHERE rp.part_rank <= 10
ORDER BY rp.part_rank, rp.total_avail_qty DESC
LIMIT 5 OFFSET 5;
