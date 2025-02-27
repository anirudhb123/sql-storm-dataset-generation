
WITH RECURSIVE supplier_sales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
    UNION ALL
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    JOIN 
        orders o ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1995-01-01' AND o.o_orderdate < '1996-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 25000
), 
nation_sales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(SUM(ss.total_sales), 0) AS total_sales,
        COUNT(ss.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier_sales ss ON ss.s_suppkey IS NOT NULL AND ss.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    n.n_name,
    ns.total_sales,
    ns.supplier_count,
    CASE 
        WHEN ns.total_sales > 100000 THEN 'High Sales'
        WHEN ns.total_sales BETWEEN 50000 AND 100000 THEN 'Medium Sales'
        ELSE 'Low Sales'
    END AS sales_category
FROM 
    nation n
JOIN 
    nation_sales ns ON n.n_nationkey = ns.n_nationkey
WHERE 
    ns.total_sales IS NOT NULL
ORDER BY 
    ns.total_sales DESC;
