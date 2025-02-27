WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CAST(s.s_name AS VARCHAR(100)) AS s_fullname,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(sh.s_fullname, ' -> ', s.s_name) AS s_fullname,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE 
        sh.level < 10
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        MAX(o.o_orderdate) AS most_recent_order
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice >= (SELECT AVG(p2.p_retailprice) FROM part p2)
            THEN 'Expensive'
            ELSE 'Cheap'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT p_size FROM part ORDER BY p_size LIMIT 5)
)
SELECT 
    r.r_name,
    SUM(os.total_revenue) AS region_revenue,
    COUNT(DISTINCT c.c_custkey) AS active_customers,
    STRING_AGG(DISTINCT fl.price_category, ', ') AS price_categories,
    COUNT(DISTINCT sh.s_fullname) AS supplier_count
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    FilteredParts fp ON ps.ps_partkey = fp.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey = ps.ps_partkey
JOIN 
    customer c ON os.unique_customers > c.c_custkey
LEFT OUTER JOIN 
    SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE 
    r.r_comment LIKE '%region%'
GROUP BY 
    r.r_name
ORDER BY 
    region_revenue DESC
LIMIT 10;
