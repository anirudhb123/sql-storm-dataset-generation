WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
TopSuppliers AS (
    SELECT 
        rnk,
        s_suppkey,
        s_name,
        s_acctbal
    FROM 
        RankedSuppliers
    WHERE 
        rnk <= 10
),
SalesSummary AS (
    SELECT 
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    s.s_name,
    s.s_acctbal,
    ss.total_sales,
    ss.total_orders
FROM 
    TopSuppliers s
JOIN 
    SalesSummary ss ON ss.total_orders > 0
ORDER BY 
    ss.total_sales DESC, s.s_acctbal DESC
LIMIT 50;
