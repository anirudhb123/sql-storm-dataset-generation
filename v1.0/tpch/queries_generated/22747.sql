WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
ranked_lineitems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_suppkey, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rn,
           SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY l.l_suppkey) AS total_cost
    FROM lineitem l
    WHERE l.l_discount BETWEEN 0.05 AND 0.07
),
suppliers_with_comments AS (
    SELECT s.s_suppkey, s.s_name, s.s_comment,
           NULLIF(SUBSTRING(s.s_comment FROM '.*(excellent|great).*'), '') AS quality_comment
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier s2
        WHERE s2.s_nationkey = s.s_nationkey 
          AND s2.s_acctbal IS NOT NULL
    )
),
aggregated_data AS (
    SELECT n.n_name, SUM(li.total_cost) AS total_revenue,
           COUNT(DISTINCT li.l_orderkey) AS order_count,
           MAX(li.total_cost) AS max_cost
    FROM ranked_lineitems li
    JOIN suppliers_with_comments s ON li.l_suppkey = s.s_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT r.r_name AS region,
       ad.n_name,
       ad.total_revenue,
       ad.order_count,
       CASE WHEN ad.max_cost IS NULL THEN 'No Sales' ELSE 'Sales Present' END AS sales_status
FROM region r
LEFT JOIN aggregated_data ad ON r.r_regionkey = (
        SELECT n.n_regionkey 
        FROM nation n 
        WHERE n.n_name = ad.n_name 
        LIMIT 1
    )
WHERE r.r_name LIKE '%North%'
ORDER BY ad.total_revenue DESC, sales_status DESC
LIMIT 10;
