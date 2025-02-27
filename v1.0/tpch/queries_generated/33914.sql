WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS hierarchy_level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.hierarchy_level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 50
),
OrderTotal AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    AND 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey
),
CustomerRegion AS (
    SELECT 
        c.c_custkey,
        r.r_name AS region_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, r.r_name
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(s.s_acctbal) AS avg_acctbal
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey
)
SELECT 
    sr.s_suppkey,
    sr.s_name,
    COALESCE(st.total_supplycost, 0) AS total_supplycost,
    COALESCE(st.avg_acctbal, 0) AS avg_acctbal,
    cr.region_name,
    cr.order_count,
    ROW_NUMBER() OVER (PARTITION BY cr.region_name ORDER BY sr.s_suppkey) AS regional_rank
FROM 
    SupplierHierarchy sr
LEFT JOIN 
    SupplierStats st ON sr.s_suppkey = st.s_suppkey
LEFT JOIN 
    CustomerRegion cr ON cr.order_count > 5
WHERE 
    sr.hierarchy_level < 3
ORDER BY 
    cr.region_name, sr.s_suppkey;
