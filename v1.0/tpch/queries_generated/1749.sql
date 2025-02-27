WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s_suppkey,
        s_name,
        total_sales,
        order_count
    FROM 
        SupplierSales
    WHERE 
        rank <= 5
),
NationSummary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(COALESCE(s.s_acctbal, 0)) AS total_acctbal,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON s.s_nationkey = n.n_nationkey
    LEFT JOIN 
        customer c ON c.c_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    t.s_name,
    t.total_sales,
    n.n_name,
    n.total_acctbal,
    n.customer_count,
    CASE 
        WHEN n.customer_count > 0 THEN ROUND(t.total_sales / n.customer_count, 2)
        ELSE 0 
    END AS avg_sales_per_customer
FROM 
    TopSuppliers t
JOIN 
    supplier s ON t.s_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
ORDER BY 
    t.total_sales DESC, n.total_acctbal DESC;
