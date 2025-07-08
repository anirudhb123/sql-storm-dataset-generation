
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate

    UNION ALL

    SELECT 
        o2.o_orderkey,
        o2.o_orderdate,
        s.revenue * 1.05 AS revenue
    FROM 
        Sales_CTE s
    JOIN 
        orders o2 ON s.o_orderkey < o2.o_orderkey
    WHERE 
        s.revenue IS NOT NULL
        AND o2.o_orderdate > (SELECT MIN(o_orderdate) FROM orders)
)

, Ranked_Sales AS (
    SELECT 
        o_orderdate,
        revenue,
        RANK() OVER (PARTITION BY o_orderdate ORDER BY revenue DESC) AS daily_rank
    FROM 
        Sales_CTE
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    COALESCE(MAX(sales_data.revenue), 0) AS max_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE 
            WHEN sales_data.daily_rank <= 5 THEN sales_data.revenue
            ELSE 0 
        END) AS top_5_revenue
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    customer c ON c.c_nationkey = s.s_nationkey
LEFT JOIN 
    Ranked_Sales sales_data ON sales_data.o_orderkey = ps.ps_partkey
WHERE 
    p.p_retailprice BETWEEN 100 AND 200
    AND (s.s_acctbal IS NULL OR s.s_acctbal >= 500.00)
    AND p.p_comment NOT LIKE '%special%'
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr
HAVING 
    COUNT(DISTINCT c.c_custkey) > 10
ORDER BY 
    max_revenue DESC
LIMIT 10;
