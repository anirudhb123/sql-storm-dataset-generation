WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 500000

    UNION ALL

    SELECT 
        ps.ps_suppkey,
        s.s_name,
        s.s_nationkey,
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        ps.ps_availqty > 100 AND sh.level < 3
), 

OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts,
        MAX(l.l_shipdate) AS last_ship_date
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),

CustomerActivity AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    c.c_custkey,
    c.c_name,
    sa.total_spent,
    COALESCE(s.s_name, 'Unknown') AS supplier,
    os.total_sales,
    os.unique_parts,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY sa.total_spent DESC) AS ranking
FROM 
    CustomerActivity sa
JOIN 
    customer c ON sa.c_custkey = c.c_custkey
LEFT JOIN 
    SupplierHierarchy s ON c.c_nationkey = s.s_nationkey
LEFT JOIN 
    OrderSummary os ON os.last_ship_date >= '2023-01-01'
WHERE 
    sa.total_orders >= 5 
    AND c.c_mktsegment IN ('BUILDING', 'FURNITURE')
ORDER BY 
    sa.total_spent DESC
LIMIT 100;
