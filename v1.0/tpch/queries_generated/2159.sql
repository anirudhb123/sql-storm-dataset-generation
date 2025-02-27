WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerRanking AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY c.c_acctbal DESC) AS rk
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 5000
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ss.total_sales
    FROM 
        supplier s
    JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        ss.total_sales > 10000
)
SELECT 
    c.c_name AS customer_name,
    ts.s_name AS supplier_name,
    ts.total_sales,
    ts.s_acctbal,
    CASE 
        WHEN ts.total_sales > 20000 THEN 'High Value Supplier'
        WHEN ts.total_sales BETWEEN 10000 AND 20000 THEN 'Medium Value Supplier'
        ELSE 'Low Value Supplier' 
    END AS supplier_category,
    cr.rk AS customer_ranking
FROM 
    TopSuppliers ts
LEFT JOIN 
    CustomerRanking cr ON ts.s_suppkey = cr.c_custkey
WHERE 
    cr.rk IS NOT NULL
ORDER BY 
    ts.total_sales DESC, cr.rk;
