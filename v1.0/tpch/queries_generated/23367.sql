WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    WHERE o.o_orderdate < CURRENT_DATE
    UNION ALL
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey, 
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_rank
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_custkey = oh.o_custkey 
                                   AND o.o_orderdate < oh.o_orderdate
    WHERE oh.order_rank < 5
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
),
NationPartCounts AS (
    SELECT n.n_name, COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name,
    n.n_name,
    COALESCE(tp.total_spent, 0) AS total_spent_by_top_customers,
    np.part_count AS distinct_part_count,
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    ROUND(AVG(o.o_totalprice), 2) AS avg_totalprice,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', p.p_name, p.p_brand, p.p_comment), '; ') AS part_details
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN TopCustomers tp ON n.n_nationkey = tp.c_nationkey
LEFT JOIN NationPartCounts np ON n.n_name = np.n_name
LEFT JOIN OrderHierarchy oh ON oh.o_custkey = tp.c_custkey
LEFT JOIN lineitem l ON oh.o_orderkey = l.l_orderkey
LEFT JOIN part p ON l.l_partkey = p.p_partkey 
WHERE (l.l_discount IS NULL OR l.l_discount > 0.05)
  AND (o.o_orderdate IS NOT NULL OR o.o_orderstatus IN ('O', 'F'))
GROUP BY r.r_name, n.n_name, np.part_count, tp.total_spent
HAVING COUNT(DISTINCT oh.o_orderkey) > 10
   OR np.part_count IS NULL
ORDER BY total_spent_by_top_customers DESC, distinct_part_count ASC NULLS LAST;
