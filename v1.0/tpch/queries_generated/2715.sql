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
        s_nationkey,
        s_suppkey,
        s_name,
        total_sales
    FROM 
        SupplierSales
    WHERE 
        sales_rank <= 3
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    n.n_name AS nation,
    ts.s_name AS top_supplier,
    co.c_name AS customer,
    COALESCE(co.total_spent, 0) AS total_spent,
    COALESCE(ts.total_sales, 0) AS supplier_sales,
    CASE 
        WHEN co.total_spent IS NULL THEN 'No Orders'
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Active'
    END AS status
FROM 
    nation n
LEFT JOIN 
    TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = ts.s_suppkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%East%')
ORDER BY 
    n.n_name, ts.total_sales DESC, co.total_spent DESC;
