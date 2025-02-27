WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        1 as level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 10000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        (s.s_acctbal + ps.ps_supplycost * ps.ps_availqty) AS total_acctbal,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        supplier_hierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal < 50000
),
order_metrics AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
    GROUP BY 
        o.o_orderkey
),
top_orders AS (
    SELECT 
        om.o_orderkey,
        om.total_revenue,
        rank() OVER (ORDER BY om.total_revenue DESC) AS revenue_rank
    FROM 
        order_metrics om
)
SELECT 
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    rh.s_name AS supplier_name,
    o.total_revenue,
    o.avg_quantity,
    o.unique_suppliers,
    COALESCE(rh.total_acctbal, 0) AS supplier_total_acctbal
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier_hierarchy rh ON ps.ps_suppkey = rh.s_suppkey
JOIN 
    top_orders o ON o.o_orderkey = ps.ps_partkey
WHERE 
    p.p_retailprice > 50.00
ORDER BY 
    o.total_revenue DESC, p.p_name;
