WITH RECURSIVE part_hierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_size, 1 AS lvl
    FROM part
    WHERE p_size < 10
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_size, ph.lvl + 1
    FROM part p
    JOIN part_hierarchy ph ON p.p_size = ph.p_size + 1
),
supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, n.n_name AS nation_name,
           SUM(CASE WHEN ps.ps_availqty IS NULL THEN 0 ELSE ps.ps_availqty END) AS total_avail_qty
    FROM supplier s
    LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
part_summary AS (
    SELECT ph.p_partkey, ph.p_name, ph.p_brand, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
           RANK() OVER (PARTITION BY ph.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS brand_rank
    FROM part_hierarchy ph
    JOIN lineitem l ON ph.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice IS NOT NULL
    GROUP BY ph.p_partkey, ph.p_name, ph.p_brand
)
SELECT pd.p_partkey, pd.p_name, pd.p_brand, 
       COALESCE(sd.s_name, 'Unknown Supplier') AS supplier_name,
       sd.nation_name, sd.total_avail_qty,
       ps.revenue, ps.brand_rank
FROM part_summary ps
LEFT JOIN supplier_details sd ON ps.p_brand = sd.s_name
FULL OUTER JOIN (SELECT p_partkey, p_name, p_brand FROM part WHERE p_container IS NULL) pd 
    ON ps.p_partkey = pd.p_partkey
WHERE (ps.revenue > 10000 OR sd.total_avail_qty IS NOT NULL) 
  AND (pd.p_name IS NOT NULL OR sd.s_acctbal IS NULL)
ORDER BY ps.brand_rank, ps.revenue DESC NULLS LAST;
