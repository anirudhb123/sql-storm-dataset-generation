WITH RecursiveCTE AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
RankedParts AS (
    SELECT 
        *,
        DENSE_RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        RecursiveCTE
)
SELECT 
    r.r_name AS region_name,
    COALESCE(n.n_name, 'Unknown') AS nation_name,
    s.s_name AS supplier_name,
    pp.p_name AS part_name,
    pp.total_sales AS total_revenue,
    CASE
        WHEN pp.total_sales IS NULL THEN 'No Sales'
        WHEN pp.total_sales > 10000 THEN 'High Revenue'
        ELSE 'Low Revenue' 
    END AS sales_category
FROM 
    RankedParts pp
LEFT JOIN 
    partsupp ps ON pp.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    (pp.sales_rank <= 10 OR pp.total_sales IS NOT NULL)
    AND (s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier WHERE s_acctbal IS NOT NULL)
         OR pp.total_sales IS NULL)
ORDER BY 
    region_name, total_revenue DESC
LIMIT 10;

WITH CTE_Supplier AS (
    SELECT 
        s_name, 
        COUNT(DISTINCT s_nationkey) AS nation_count
    FROM 
        supplier
    GROUP BY 
        s_name
    HAVING 
        COUNT(DISTINCT s_nationkey) > 1
)
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice) AS total_value
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderstatus IN ('O', 'F')
    AND (s.s_comment LIKE '%special%' OR s.s_comment IS NULL)
GROUP BY 
    s.s_name
HAVING 
    SUM(l.l_extendedprice) > (SELECT AVG(total_value) FROM (
        SELECT SUM(l_extendedprice) AS total_value
        FROM lineitem
        GROUP BY l_orderkey) tmp)
ORDER BY 
    total_value DESC;
