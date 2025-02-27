
WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS rn
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
), 
TopSuppliers AS (
    SELECT 
        si.s_suppkey,
        si.s_name,
        si.s_acctbal,
        si.total_sales
    FROM 
        SupplierInfo si
    WHERE 
        si.rn <= 3
)

SELECT 
    c.c_name,
    c.c_acctbal,
    COALESCE(ts.total_sales, 0) AS supplier_sales,
    CASE 
        WHEN ts.total_sales IS NOT NULL AND c.c_acctbal >= 2000 THEN 'High Value' 
        ELSE 'Regular'
    END AS customer_value,
    COUNT(o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    customer c
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    TopSuppliers ts ON c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_nationkey = ts.s_suppkey)
WHERE 
    c.c_acctbal IS NOT NULL 
    AND o.o_orderstatus = 'O'
GROUP BY 
    c.c_name, c.c_acctbal, ts.total_sales
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    supplier_sales DESC, c.c_name;
