WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, CAST(s.s_name AS varchar(100)) AS path, 1 AS level
    FROM supplier s
    WHERE s.s_nationkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'N%')
    UNION ALL
    SELECT sh.s_suppkey, sh.s_name, sh.s_nationkey, CONCAT(s.path, ' -> ', sh.s_name), sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier s ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
part_supplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, SUM(ps.ps_availqty) AS total_avail_qty, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey, ps.ps_suppkey
),
nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY n.n_nationkey, r.r_regionkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(sh.path, 'No Suppliers') AS supplier_hierarchy,
    COALESCE(ps.total_avail_qty, 0) AS total_available_qty,
    COALESCE(ps.avg_supply_cost, 0) AS average_supply_cost,
    CONCAT(nr.n_name, ' (', nr.customer_count, ' customers)') AS nation_customer_info,
    ROW_NUMBER() OVER (PARTITION BY nr.r_regionkey ORDER BY p.p_retailprice DESC) AS rank_by_price,
    CASE 
        WHEN p.p_size IS NULL THEN 'Unknown Size'
        WHEN p.p_size < 10 THEN 'Small'
        WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
        ELSE 'Large'
    END AS size_category
FROM part p
LEFT JOIN part_supplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey IN (SELECT ps.ps_suppkey FROM part_supplier ps WHERE ps.ps_partkey = p.p_partkey)
JOIN nation_region nr ON nr.n_nationkey = (SELECT DISTINCT n.n_nationkey FROM nation n WHERE n.n_regionkey = nr.r_regionkey LIMIT 1)
WHERE 
    (p.p_retailprice > 100 OR p.p_comment IS NOT NULL)
    AND (ps.total_avail_qty IS NOT NULL OR ps.avg_supply_cost IS NOT NULL)
ORDER BY p.p_partkey, rank_by_price DESC;
