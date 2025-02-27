WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        0 AS order_level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus = 'O'
    
    UNION ALL
    
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        oh.order_level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_custkey
    WHERE 
        o.o_orderdate > oh.o_orderdate
),
SupplierSales AS (
    SELECT 
        ps.ps_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM 
        partsupp ps
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        ps.ps_partkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.ps_partkey
    WHERE 
        ss.total_sales IS NOT NULL
    ORDER BY 
        ss.total_sales DESC
    LIMIT 5
),
CustomerRegions AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        n.n_regionkey,
        r.r_name
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    cr.c_name,
    cr.r_name AS region,
    COUNT(DISTINCT oh.o_orderkey) AS order_count,
    SUM(ps.ps_supplycost) AS total_supply_cost,
    AVG(CASE WHEN oh.order_level > 0 THEN oh.o_orderkey END) AS avg_hierarchy_level,
    COALESCE(SUM(ss.total_sales), 0) AS total_supplier_sales
FROM 
    CustomerRegions cr
LEFT JOIN 
    OrderHierarchy oh ON cr.c_custkey = oh.o_custkey
LEFT JOIN 
    partsupp ps ON cr.c_custkey = ps.ps_suppkey
LEFT JOIN 
    TopSuppliers ts ON ps.ps_partkey = ts.ps_partkey
GROUP BY 
    cr.c_name, 
    cr.r_name
HAVING 
    COUNT(DISTINCT oh.o_orderkey) > 5
ORDER BY 
    total_supplier_sales DESC;
