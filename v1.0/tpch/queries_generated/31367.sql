WITH RECURSIVE OrderHierarchy AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CAST(o.o_orderkey AS VARCHAR) AS hierarchy_path
    FROM orders o
    WHERE o.o_orderstatus = 'O'
    UNION ALL
    SELECT
        li.l_orderkey,
        li.l_shipdate AS o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) OVER (PARTITION BY li.l_orderkey) AS o_totalprice,
        o.o_orderstatus,
        CONCAT(oh.hierarchy_path, '->', li.l_orderkey) AS hierarchy_path
    FROM lineitem li
    JOIN OrderHierarchy oh ON li.l_orderkey = oh.o_orderkey
    JOIN orders o ON li.l_orderkey = o.o_orderkey
)
SELECT 
    c.c_name,
    SUM(oh.o_totalprice) AS total_revenue,
    AVG(oh.o_totalprice) AS avg_order_value,
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(oh.o_totalprice) > 100000 THEN 'High Value'
        WHEN SUM(oh.o_totalprice) BETWEEN 50000 AND 100000 THEN 'Medium Value'
        ELSE 'Low Value' 
    END AS revenue_category
FROM customer c
LEFT JOIN OrderHierarchy oh ON c.c_custkey = oh.o_orderkey
WHERE 
    c.c_acctbal IS NOT NULL 
    AND c.c_name NOT LIKE '%test%'
    AND oh.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY c.c_name
HAVING COUNT(DISTINCT oh.o_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
