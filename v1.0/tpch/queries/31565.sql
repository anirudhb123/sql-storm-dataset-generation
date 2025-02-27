
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        CAST(NULL AS integer) AS parent_suppkey, 
        0 AS hierarchy_level 
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        sh.s_suppkey AS parent_suppkey, 
        sh.hierarchy_level + 1 
    FROM 
        supplier s 
    JOIN 
        SupplierHierarchy sh ON s.s_acctbal < sh.s_acctbal 
    WHERE 
        sh.hierarchy_level < 5
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_totalprice, 
        o.o_orderdate, 
        o.o_orderstatus 
    FROM 
        orders o 
    WHERE 
        o.o_orderstatus = 'O' 
        AND o.o_orderdate >= '1997-01-01' 
),
LineitemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(l.total_revenue) AS total_revenue,
    AVG(l.avg_quantity) AS average_quantity,
    MIN(s.s_acctbal) AS min_supplier_balance,
    MAX(s.s_acctbal) AS max_supplier_balance,
    CASE 
        WHEN SUM(l.total_revenue) IS NULL THEN 'No Sales'
        ELSE 'Sales Present' 
    END AS sales_indicator,
    region.r_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    LineitemStats l ON ps.ps_partkey = l.l_orderkey
LEFT JOIN 
    FilteredOrders fo ON l.l_orderkey = fo.o_orderkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region ON n.n_regionkey = region.r_regionkey
GROUP BY 
    p.p_name, p.p_brand, region.r_name
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 1 
ORDER BY 
    total_revenue DESC
LIMIT 10;
