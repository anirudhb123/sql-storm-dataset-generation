WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        total_sales
    FROM 
        SupplierSales s
    WHERE 
        total_sales > (SELECT AVG(total_sales) FROM SupplierSales)
),
NationalSummary AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        SUM(COALESCE(ss.total_sales, 0)) AS total_sales,
        SUM(CASE WHEN ss.total_sales IS NOT NULL THEN 1 ELSE 0 END) AS active_supplier_count
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    ns.n_name,
    ns.supplier_count,
    ns.total_sales,
    ns.active_supplier_count,
    ch.avg_order_value
FROM 
    NationalSummary ns
LEFT JOIN 
    CustomerOrders ch ON ns.n_nationkey = ch.c_nationkey
WHERE 
    ns.supplier_count > 10
ORDER BY 
    total_sales DESC, avg_order_value DESC
LIMIT 10;
