WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey AS nation_key, n.n_name AS nation_name, r.r_name AS region_name, 0 AS level
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE r.r_name IS NOT NULL
    UNION ALL
    SELECT nh.nation_key, nh.nation_name, r.r_name, nh.level + 1
    FROM NationHierarchy nh
    JOIN nation n ON nh.nation_name <> n.n_name
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    c.c_name AS customer_name,
    c.c_acctbal,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS sales_rank,
    COUNT(o.o_orderkey) AS order_count,
    nh.region_name,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Value'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN NationHierarchy nh ON c.c_nationkey = nh.nation_key
WHERE c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
GROUP BY c.c_name, c.c_acctbal, nh.region_name
HAVING COUNT(o.o_orderkey) > 5
ORDER BY total_sales DESC, customer_name
LIMIT 10;
