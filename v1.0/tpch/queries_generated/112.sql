WITH SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        n.n_name,
        ss.s_name,
        ss.total_sales,
        ss.sales_rank
    FROM 
        nation n
    LEFT JOIN 
        SupplierSales ss ON n.n_nationkey = ss.s_suppkey
    WHERE 
        ss.sales_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        c.c_nationkey
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_nationkey
)
SELECT 
    t.n_name AS nation_name,
    t.s_name AS supplier_name,
    t.total_sales,
    COALESCE(co.total_spent, 0) AS total_spent_by_customers,
    (CASE WHEN COALESCE(co.order_count, 0) > 0 THEN 'Has Orders' ELSE 'No Orders' END) AS order_status
FROM 
    TopSuppliers t
LEFT JOIN 
    CustomerOrders co ON t.s_nationkey = co.c_nationkey
ORDER BY 
    t.n_name, t.total_sales DESC;
