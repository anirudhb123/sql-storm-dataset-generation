WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS hierarchy_level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
nation_region AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_name, n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_type,
    COALESCE(os.total_line_price, 0) AS total_sales,
    COALESCE(nr.supplier_count, 0) AS supplier_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY COALESCE(os.total_line_price, 0) DESC) AS rank_within_brand
FROM part p
LEFT JOIN order_summary os ON p.p_partkey = os.o_orderkey
LEFT JOIN nation_region nr ON p.p_size = nr.supplier_count
WHERE p.p_retailprice > 50.00
  AND (p.p_mfgr LIKE '%ABC%' OR NULLIF(p.p_comment, '') IS NULL)
  AND NOT EXISTS (
      SELECT 1
      FROM partsupp ps
      WHERE ps.ps_partkey = p.p_partkey
      AND ps.ps_availqty < 5
  )
ORDER BY total_sales DESC, p.p_name;
