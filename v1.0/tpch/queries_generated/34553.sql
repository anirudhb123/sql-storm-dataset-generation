WITH RECURSIVE category_hierarchy AS (
    SELECT 
        p_partkey,
        p_name,
        p_mfgr,
        p_brand,
        p_type,
        p_size,
        p_container,
        p_retailprice,
        p_comment,
        1 AS level
    FROM 
        part
    WHERE 
        p_type LIKE 'Category%'

    UNION ALL

    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        ch.level + 1
    FROM 
        part p
    JOIN 
        category_hierarchy ch ON p.p_type LIKE CONCAT(ch.p_name, '%')
)

SELECT 
    c.c_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(daily_revenue) AS avg_daily_revenue
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS daily_revenue,
        CAST(l_shipdate AS DATE) AS ship_date
    FROM 
        lineitem
    GROUP BY 
        l_orderkey, 
        l_shipdate
) AS revenue ON l.l_orderkey = revenue.l_orderkey
JOIN 
    category_hierarchy ch ON l.l_partkey = ch.p_partkey
WHERE 
    o.o_orderstatus = 'F'
    AND (ch.p_retailprice < 100 OR ch.p_brand IN (SELECT s_brand FROM supplier WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')))
    AND l.l_shipmode = 'AIR'
GROUP BY 
    c.c_name
HAVING 
    total_revenue > 
    (
        SELECT AVG(total) 
        FROM (
            SELECT 
                SUM(l_extendedprice * (1 - l_discount)) AS total
            FROM 
                lineitem
            GROUP BY 
                l_orderkey
        ) AS subquery
    )
ORDER BY 
    total_revenue DESC
LIMIT 10;
