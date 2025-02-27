WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000
    
    UNION ALL
    
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sh.level + 1
    FROM 
        supplier s
    JOIN 
        SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey 
    WHERE 
        s.s_acctbal > 1000
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size BETWEEN 15 AND 30 AND 
        p.p_comment LIKE '%urgent%'
),
OrderSums AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '2023-01-01' AND 
        l.l_shipdate < '2023-12-31'
    GROUP BY 
        o.o_orderkey
),
SupplierStats AS (
    SELECT 
        s.n_nationkey,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    LEFT JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.n_nationkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.total_revenue) AS total_order_revenue,
    SUM(ps.profit_margin) AS total_profit_margin,
    ss.supplier_count,
    ss.total_acctbal,
    CASE 
        WHEN SUM(o.total_revenue) > 100000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    OrderSums o ON c.c_custkey = o.o_orderkey
LEFT JOIN 
    FilteredParts ps ON ps.p_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
LEFT JOIN 
    SupplierStats ss ON n.n_nationkey = ss.n_nationkey
GROUP BY 
    r.r_name, ss.supplier_count, ss.total_acctbal
ORDER BY 
    customer_count DESC, total_order_revenue DESC;
