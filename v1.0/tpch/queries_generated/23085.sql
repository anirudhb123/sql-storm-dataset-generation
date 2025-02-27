WITH RECURSIVE supplier_chain AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000 -- starting point with suppliers having more than $1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN supplier_chain sc ON o.o_custkey = sc.s_suppkey -- recursive join through orders
    WHERE s.s_acctbal < sc.s_acctbal -- establish a bizarre flow of suppliers based on account balance
    AND sc.level < 5 -- limiting depth of recursion to 5 levels for performance
)

SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(CASE WHEN sc.level = 0 THEN s.s_acctbal ELSE 0 END) AS root_supplier_acctbal,
    SUM(s.s_acctbal) FILTER (WHERE s.s_acctbal IS NOT NULL) AS total_supplier_acctbal,
    AVG(ps.ps_supplycost) OVER (PARTITION BY n.n_name) AS avg_supplycost_per_nation,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': $', s.s_acctbal), '; ') AS suppliers,
    CASE 
        WHEN COUNT(s.s_suppkey) > 10 THEN 'Many suppliers'
        WHEN COUNT(s.s_suppkey) BETWEEN 5 AND 10 THEN 'Moderate suppliers'
        ELSE 'Few suppliers'
    END AS supplier_category
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN supplier_chain sc ON s.s_suppkey = sc.s_suppkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY r.r_name, n.n_name
ORDER BY region_name, nation_name
HAVING SUM(CASE WHEN s.s_acctbal < 0 THEN 1 ELSE 0 END) = 0 -- ensuring no suppliers with negative account balance
   AND COUNT(s.s_suppkey) > 2 -- ensuring at least 3 suppliers are present
   AND MAX(sc.level) IS NOT NULL; -- additional check for suppliers with levels in the chain
