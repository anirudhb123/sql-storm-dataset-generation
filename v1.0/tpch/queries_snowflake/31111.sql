
WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        oi.o_orderkey,
        oi.o_orderdate,
        oi.o_totalprice,
        oh.level + 1
    FROM 
        orders oi
    JOIN 
        OrderHierarchy oh ON oi.o_orderkey = oh.o_orderkey
),
SupplierSummary AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey
),
CustomerRevenue AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(cs.order_count, 0) AS order_count,
    SUM(ss.total_available) AS total_available_parts,
    AVG(ss.supplier_count) AS avg_suppliers,
    COUNT(DISTINCT oh.o_orderkey) AS order_count_recursive
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierSummary ss ON s.s_suppkey = ss.p_partkey
LEFT JOIN 
    CustomerRevenue cs ON s.s_nationkey = cs.c_custkey
LEFT JOIN 
    OrderHierarchy oh ON cs.c_custkey = oh.o_orderkey
WHERE 
    r.r_comment LIKE '%important%'
GROUP BY 
    r.r_name, cs.total_spent, cs.order_count
HAVING 
    SUM(COALESCE(cs.total_spent, 0)) > 10000
ORDER BY 
    r.r_name DESC;
