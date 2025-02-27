WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT 
        s2.s_suppkey,
        s2.s_name,
        s2.s_acctbal,
        sh.level + 1
    FROM 
        supplier s2
    JOIN 
        partsupp ps ON ps.ps_suppkey = s2.s_suppkey
    JOIN 
        SupplierHierarchy sh ON sh.s_suppkey = ps.ps_suppkey
    WHERE 
        s2.s_acctbal < sh.s_acctbal AND sh.level < 5
),

TotalSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' 
    GROUP BY 
        o.o_orderkey
),

FilteredSupplier AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
            ELSE 'Known Balance'
        END AS balance_status
    FROM 
        supplier s
    WHERE 
        s.s_comment NOT LIKE '%test%'
)

SELECT 
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN l.l_extendedprice ELSE NULL END) AS avg_building_price,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    COUNT(DISTINCT CASE WHEN li.rnk = 1 THEN l.l_orderkey END) AS one_time_orders,
    MAX(CASE WHEN r.r_regionkey IS NULL THEN 'No Region' ELSE r.r_name END) AS region_name,
    ARRAY_AGG(DISTINCT sh.s_name) AS supplier_names
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    (
        SELECT 
            l.lineitem_orderkey,
            DENSE_RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS rnk 
        FROM 
            lineitem l
    ) li ON l.l_orderkey = li.lineitem_orderkey
LEFT JOIN 
    FilteredSupplier fs ON fs.s_suppkey = l.l_suppkey
LEFT JOIN 
    SupplierHierarchy sh ON sh.s_suppkey = l.l_suppkey
WHERE 
    (l.l_discount BETWEEN 0.05 AND 0.25 OR l.l_returnflag = 'A')
    AND (p.p_size BETWEEN 10 AND 30 OR p.p_comment IS NOT NULL)
GROUP BY 
    p.p_name
ORDER BY 
    total_quantity DESC
FETCH FIRST 10 ROWS ONLY;
