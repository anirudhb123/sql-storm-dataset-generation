WITH RECURSIVE nation_sales AS (
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY n.n_nationkey, n.n_name
    UNION ALL
    SELECT n.n_nationkey, n.n_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN nation_sales ns ON n.n_nationkey = ns.n_nationkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate > '2024-01-01'
    GROUP BY n.n_nationkey, n.n_name
),
top_nations AS (
    SELECT n.n_name, ns.total_sales,
           RANK() OVER (ORDER BY ns.total_sales DESC) AS sales_rank
    FROM nation_sales ns
    JOIN nation n ON ns.n_nationkey = n.n_nationkey
)
SELECT COALESCE(tn.n_name, 'Unknown') AS nation_name,
       COALESCE(tn.total_sales, 0) AS total_sales,
       CASE WHEN tn.sales_rank IS NULL THEN 'Unranked'
            ELSE tn.sales_rank::text END AS sales_rank
FROM top_nations tn
RIGHT JOIN region r ON tn.n_name IS NULL AND r.r_regionkey = 1
ORDER BY tn.sales_rank DESC NULLS LAST
LIMIT 10;

-- Include a bizarre NULL logic condition just to stir things a bit
SELECT DISTINCT r.r_name, 
   CASE WHEN EXISTS (
      SELECT 1
      FROM customer c
      WHERE c.c_nationkey IS NULL
   ) THEN 'Missing Nation Info'
   ELSE 'All Good'
   END AS nation_info
FROM region r
LEFT OUTER JOIN nation n ON r.r_regionkey = n.n_regionkey
WHERE (n.n_nationkey IS NULL OR r.r_name IS NOT NULL)
AND EXISTS (
    SELECT 1
    FROM supplier s
    WHERE s.s_nationkey = n.n_nationkey
    HAVING COUNT(s.s_suppkey) > 0
)
ORDER BY random() -- throwing a twist with random ordering
LIMIT 5;
