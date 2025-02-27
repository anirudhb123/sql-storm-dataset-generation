WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal, 
        0 AS hierarchy_level 
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT 
        p.ps_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        (s.s_acctbal + p.ps_supplycost) AS updated_acctbal, 
        sh.hierarchy_level + 1 
    FROM 
        partsupp p 
    JOIN 
        SupplierHierarchy sh ON p.ps_suppkey = sh.s_suppkey 
    JOIN 
        supplier s ON p.ps_suppkey = s.s_suppkey 
    WHERE 
        p.ps_availqty > 0
),

AggregatedSales AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales, 
        SUM(l.l_tax) AS total_tax 
    FROM 
        orders o 
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey 
    WHERE 
        o.o_orderstatus = 'F' 
        AND l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY 
        o.o_orderkey
),

HighValueOrders AS (
    SELECT 
        a.o_orderkey, 
        a.total_sales, 
        a.total_tax, 
        sh.s_name, 
        sh.hierarchy_level 
    FROM 
        AggregatedSales a 
    LEFT JOIN 
        SupplierHierarchy sh ON a.total_sales > 1000 
    WHERE 
        sh.hierarchy_level <= 5
)

SELECT 
    h.o_orderkey,
    h.total_sales, 
    h.total_tax, 
    COALESCE(h.s_name, 'No Supplier') AS supplier_name, 
    COALESCE(sh.r_name, 'Unknown Region') AS region_name 
FROM 
    HighValueOrders h 
LEFT JOIN 
    nation n ON h.s_nationkey = n.n_nationkey 
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
ORDER BY 
    h.total_sales DESC
LIMIT 100;
