WITH RECURSIVE nation_sales AS (
    SELECT 
        n.n_name AS nation_name, 
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_sales,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS sales_rank
    FROM 
        nation n
    LEFT OUTER JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    LEFT JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        n.n_nationkey, n.n_name
), ranked_nation_sales AS (
    SELECT 
        nation_name, 
        customer_count,
        total_sales,
        CASE 
            WHEN sales_rank = 1 THEN 'Top Nation'
            WHEN sales_rank = 2 THEN 'Second Nation'
            ELSE 'Other Nations' 
        END AS rank_category
    FROM 
        nation_sales
)
SELECT 
    rns.nation_name, 
    rns.customer_count, 
    rns.total_sales, 
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)) OVER (PARTITION BY rns.nation_name), 0) AS adjusted_sales,
    SUBSTRING(rns.nation_name FROM 1 FOR 5) || '...' AS short_name,
    CASE 
        WHEN rns.total_sales IS NULL THEN 'No Sales'
        WHEN rns.total_sales BETWEEN 0 AND 10000 THEN 'Low Sales'
        WHEN rns.total_sales BETWEEN 10001 AND 50000 THEN 'Medium Sales'
        ELSE 'High Sales'
    END AS sales_bracket
FROM 
    ranked_nation_sales rns
LEFT JOIN 
    lineitem l ON EXISTS (
        SELECT 1
        FROM orders o 
        WHERE o.o_custkey IN (
            SELECT c.c_custkey 
            FROM customer c 
            WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = rns.nation_name)
        ) AND l.l_orderkey = o.o_orderkey
    )
WHERE 
    rns.total_sales IS NOT NULL
ORDER BY 
    rns.customer_count DESC, 
    rns.total_sales DESC 
LIMIT 10;
