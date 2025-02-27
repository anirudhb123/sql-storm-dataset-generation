WITH regional_sales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        o.o_orderdate BETWEEN '2021-01-01' AND '2021-12-31'
        AND l.l_returnflag = 'N'
    GROUP BY 
        r.r_name
),
top_regions AS (
    SELECT 
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS region_rank
    FROM 
        regional_sales
)
SELECT 
    tr.region_name,
    COALESCE(tr.total_sales, 0) AS total_sales,
    ROUND((SELECT AVG(total_sales) FROM top_regions WHERE region_rank <= 3), 2) AS avg_top_sales,
    CASE 
        WHEN tr.total_sales > ROUND((SELECT AVG(total_sales) FROM top_regions), 2) THEN 'Above Average'
        ELSE 'Below Average'
    END AS sales_comparison,
    (SELECT COUNT(*) FROM supplier s WHERE s.s_acctbal > 
        (SELECT AVG(s_acctbal) FROM supplier) AND s.s_nationkey = n.n_nationkey) AS affluent_suppliers_count
FROM 
    top_regions tr
LEFT JOIN 
    nation n ON tr.region_name = (SELECT r.r_name FROM region r WHERE r.r_regionkey IN 
        (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = c.c_nationkey LIMIT 1) LIMIT 1)
ORDER BY 
    tr.total_sales DESC 
LIMIT 10;

WITH RECURSIVE supply_chain(suppkey, path) AS (
    SELECT 
        s.s_suppkey,
        s.s_name 
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    UNION ALL
    SELECT 
        ps.ps_suppkey,
        CONCAT(sc.path, ' -> ', s.s_name)
    FROM 
        supply_chain sc
    JOIN 
        partsupp ps ON sc.suppkey = ps.ps_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT 
    path
FROM 
    supply_chain 
WHERE 
    path IS NOT NULL
ORDER BY 
    LENGTH(path) DESC;

SELECT 
    p.p_name,
    COUNT(l.l_partkey) AS total_sold,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_name
HAVING 
    SUM(l.l_extendedprice) IS NOT NULL 
    OR COUNT(l.l_partkey) < 10
ORDER BY 
    total_revenue DESC;

SELECT 
    DISTINCT s_name
FROM 
    supplier 
WHERE 
    s_acctbal IS NOT NULL 
    AND s_acctbal NOT BETWEEN 5000 AND 10000 
    AND (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_supplycost > 50 AND ps.ps_partkey IN (SELECT p_partkey FROM part WHERE p_size > 10)) > 5 
ORDER BY 
    s_name DESC;

WITH potential_sales AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS potential_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey
)
SELECT 
    p.p_name,
    COUNT(ps.c_custkey) AS customer_count,
    SUM(ps.potential_revenue) AS potential_revenue
FROM 
    part p
JOIN 
    potential_sales ps ON ps.c_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'N%' LIMIT 1) LIMIT 1)
GROUP BY 
    p.p_name
HAVING 
    SUM(ps.potential_revenue) > (
        SELECT 
            AVG(potential_revenue) FROM potential_sales
    )
ORDER BY 
    customer_count DESC;
