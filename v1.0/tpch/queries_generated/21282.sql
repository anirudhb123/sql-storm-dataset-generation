WITH recursive part_supplier_data AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, s.s_suppkey, s.s_name, ps.ps_availqty, ps.ps_supplycost, ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE p.p_retailprice IS NOT NULL
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_brand, NULL, NULL, 0, 0
    FROM part p
    WHERE NOT EXISTS (
        SELECT 1 FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey
    )
),
order_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
nation_details AS (
    SELECT n.n_nationkey, n.n_name, r.r_name AS region_name
    FROM nation n
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    psd.p_partkey,
    psd.p_name,
    psd.p_brand,
    n.n_name AS nation_name,
    COALESCE(os.total_revenue, 0) AS order_revenue,
    CASE 
        WHEN psd.rn IS NOT NULL AND psd.rn = 1 THEN 'Highest Supply Cost'
        ELSE 'Other'
    END AS supply_rank,
    COUNT(*) OVER (PARTITION BY psd.p_partkey) AS supplier_count
FROM part_supplier_data psd
LEFT JOIN order_summary os ON psd.p_partkey = os.o_orderkey
LEFT JOIN nation_details n ON psd.s_suppkey = n.n_nationkey
WHERE (psd.ps_availqty > 0 OR psd.ps_supplycost IS NULL)
AND (psd.p_brand LIKE 'Brand%' OR n.n_name IS NOT NULL)
ORDER BY order_revenue DESC NULLS LAST, psd.p_name;
