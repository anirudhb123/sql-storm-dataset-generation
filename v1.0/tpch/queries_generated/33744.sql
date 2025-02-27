WITH RECURSIVE region_hierarchy AS (
    SELECT r_regionkey, r_name, r_comment, 0 as level
    FROM region
    WHERE r_name LIKE 'N%'

    UNION ALL

    SELECT r.r_regionkey, r.r_name, r.r_comment, rh.level + 1
    FROM region r
    JOIN region_hierarchy rh ON r.r_regionkey = rh.r_regionkey
    WHERE rh.level < 5
),
supplier_summary AS (
    SELECT s.nationkey, SUM(s.s_acctbal) as total_acctbal
    FROM supplier s
    GROUP BY s.nationkey
),
part_with_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_supplycost, p.p_retailprice, s.total_acctbal
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier_summary s ON s.nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = p.p_partkey % 5)
)
SELECT 
    r.r_name AS region_name,
    COALESCE(SUM(CASE WHEN l.l_shipdate < CURRENT_DATE - INTERVAL '30 days' THEN l.l_extendedprice END), 0) AS old_sales,
    AVG(p.ps_supplycost - p.p_retailprice) AS avg_margin,
    COUNT(DISTINCT o.o_orderkey) OVER (PARTITION BY r.r_name) as total_orders
FROM region_hierarchy r
LEFT JOIN lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
LEFT JOIN part_with_supplier p ON p.ps_supplycost > 100
LEFT JOIN supplier s ON p.total_acctbal < s.s_acctbal
LEFT JOIN customer c ON c.c_nationkey = s.s_nationkey
GROUP BY r.r_name
HAVING AVG(p.ps_supplycost) > 50
ORDER BY old_sales DESC, region_name;
