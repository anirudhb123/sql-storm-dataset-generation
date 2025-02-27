WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 0 AS level
    FROM supplier
    WHERE s_nationkey IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 0 AND p.p_retailprice IS NOT NULL
);
SELECT 
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    MAX(CASE WHEN l.l_returnflag = 'R' THEN 1 ELSE 0 END) AS returned_items,
    STRING_AGG(CASE WHEN p.p_comment IS NULL THEN 'No Comment' ELSE p.p_comment END, ', ') AS part_comments
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON ps.ps_partkey = l.l_partkey
LEFT JOIN FilteredParts fp ON fp.p_partkey = ps.ps_partkey AND fp.rn <= 5
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING SUM(l.l_quantity) < (SELECT AVG(l2.l_quantity) FROM lineitem l2 
                             WHERE l2.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31')
ORDER BY total_sales DESC, customer_count ASC
OPTION (MAXDOP 4);
