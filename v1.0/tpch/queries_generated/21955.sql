WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS lvl
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, sh.lvl + 1
    FROM supplier_hierarchy sh
    JOIN partsupp ps ON sh.s_suppkey = ps.ps_suppkey
    JOIN supplier s ON ps.ps_partkey = s.s_suppkey
    WHERE sh.lvl < 3
),
products_with_avg_price AS (
    SELECT p.p_partkey, AVG(ps.ps_supplycost) AS avg_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
),
filtered_orders AS (
    SELECT o.o_orderkey, o.o_totalprice, DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS sales_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
),
nations_with_comment AS (
    SELECT n.n_nationkey, n.n_name, 
           CASE WHEN n.n_comment LIKE '%important%' THEN 1 ELSE 0 END AS important_flag
    FROM nation n
    WHERE n.n_name IS NOT NULL
)
SELECT 
    s.s_name,
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returns,
    COALESCE(TOTAL_SALES.total_sales, 0) AS total_sales,
    ROUND(AVG(p.avg_cost) OVER (PARTITION BY r.r_regionkey ORDER BY p.avg_cost ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING), 2) AS region_avg_cost
FROM 
    supplier s
LEFT JOIN 
    supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    orders o ON o.o_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = s.s_nationkey 
        LIMIT 1)
LEFT JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    nation n ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    region r ON r.r_regionkey = n.n_regionkey
OUTER APPLY (
    SELECT SUM(COALESCE(o2.o_totalprice, 0)) AS total_sales 
    FROM filtered_orders o2 
    WHERE o2.o_orderkey = o.o_orderkey
) AS TOTAL_SALES
WHERE 
    r.r_name NOT IN (SELECT r_name FROM region WHERE r_comment IS NULL)
    AND (s.s_acctbal IS NOT NULL OR sh.lvl IS NOT NULL)
GROUP BY 
    s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10 
    AND SUM(l.l_quantity) BETWEEN 100 AND 1000
ORDER BY 
    region_avg_cost DESC, total_sales DESC;
