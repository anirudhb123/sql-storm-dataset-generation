WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, n_comment, 0 AS depth
    FROM nation
    WHERE n_regionkey = 1
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, n.n_comment, nh.depth + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_nationkey = nh.n_regionkey
), 
supplier_stats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
)
SELECT 
    n.n_name AS nation_name,
    s.s_name AS supplier_name,
    COALESCE(ss.total_supply_value, 0) AS total_supply_value,
    CASE 
        WHEN ss.rnk IS NULL THEN 'Not Ranked'
        ELSE CAST(ss.rnk AS VARCHAR)
    END AS supplier_rank,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(l.l_quantity) AS avg_lineitem_quantity
FROM nation n
LEFT JOIN supplier_stats ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN orders o ON ss.s_suppkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE n.n_comment NOT LIKE '%some comment%'
GROUP BY n.n_name, s.s_name, ss.total_supply_value, ss.rnk
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 
   OR ss.total_parts > 5
ORDER BY total_supply_value DESC, nation_name ASC
LIMIT 100;
