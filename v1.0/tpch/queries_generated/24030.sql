WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CAST(s.s_name AS VARCHAR(100)) AS full_path,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 0
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CONCAT(sh.full_path, ' -> ', s.s_name),
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE 
        sh.level < 5
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_supplycost 
                     FROM partsupp ps 
                     WHERE ps.ps_availqty > 0)
),
NationSuppliers AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
OrderMetrics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_discount) AS avg_discount,
        COUNT(l.l_orderkey) AS items_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    ph.p_partkey,
    ph.p_name,
    ph.p_retailprice,
    IFNULL(ns.supplier_count, 0) AS associated_suppliers,
    om.total_revenue,
    om.avg_discount,
    om.items_count,
    sh.full_path
FROM 
    FilteredParts ph
FULL OUTER JOIN 
    NationSuppliers ns ON ph.p_partkey = ns.n_nationkey
LEFT JOIN 
    OrderMetrics om ON ph.p_partkey = om.o_orderkey
LEFT JOIN 
    SupplierHierarchy sh ON ph.p_partkey = sh.s_suppkey
WHERE 
    (ph.price_rank <= 3 OR ns.supplier_count IS NOT NULL)
    AND (om.total_revenue IS NULL OR om.total_revenue > 1000)
ORDER BY 
    ph.p_partkey DESC,
    associated_suppliers ASC NULLS LAST;
