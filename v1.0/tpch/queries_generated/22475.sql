WITH RecursiveCTE AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand,
           p.p_retailprice,
           CASE 
               WHEN p.p_size IS NULL THEN 'Unknown Size'
               WHEN p.p_size < 10 THEN 'Small'
               WHEN p.p_size BETWEEN 10 AND 20 THEN 'Medium'
               ELSE 'Large' 
           END AS size_category
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    
    UNION ALL
    
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand,
           p.p_retailprice * (1 - COALESCE(l.l_discount, 0)) AS discounted_price,
           r.size_category
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN RecursiveCTE r ON p.p_partkey = r.p_partkey
    WHERE r.size_category = 'Medium' AND l.l_returnflag = 'Y'
),
OrderedNations AS (
    SELECT n.n_name,
           RANK() OVER (PARTITION BY n.n_regionkey ORDER BY a.avg_price DESC) as nation_rank,
           a.avg_price
    FROM nation n
    JOIN (
        SELECT s.n_nationkey, 
               AVG(ps.ps_supplycost) AS avg_price
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        GROUP BY s.n_nationkey
    ) a ON n.n_nationkey = a.n_nationkey
)
SELECT DISTINCT r.size_category as part_size,
                COUNT(DISTINCT c.c_custkey) AS customer_count,
                AVG(l.l_extendedprice) AS avg_lineitem_price,
                SUM(CASE WHEN o.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS finished_orders
FROM RecursiveCTE r
JOIN lineitem l ON r.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN region rg ON rg.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey)
WHERE r.discounted_price IS NOT NULL 
  AND EXISTS (SELECT 1 FROM OrderedNations ON n.n_nationkey = c.c_nationkey 
              WHERE nation_rank <= 3)
GROUP BY r.size_category
HAVING AVG(l.l_extendedprice) > 100 
  AND COUNT(DISTINCT c.c_custkey) > 10 
ORDER BY part_size, finished_orders DESC;
