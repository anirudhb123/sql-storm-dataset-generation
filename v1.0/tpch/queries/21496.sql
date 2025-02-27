WITH RECURSIVE SupplierSales AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * l.l_extendedprice * (1 - l.l_discount)) AS total_sale
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' 
        AND l.l_shipdate < DATE '1998-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        COALESCE(ss.total_sale, 0) AS total_sale
    FROM 
        supplier s
    LEFT JOIN 
        SupplierSales ss ON s.s_suppkey = ss.s_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(hv.total_sale) AS total_sales_value,
    AVG(hv.total_sale) AS avg_sales_per_supplier,
    STRING_AGG(DISTINCT CASE WHEN hv.total_sale > 10000 THEN hv.s_name END, ', ') AS high_value_supplier_names
FROM 
    region r
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
JOIN 
    HighValueSuppliers hv ON c.c_nationkey = (SELECT n_nationkey FROM supplier WHERE s_suppkey = hv.s_suppkey LIMIT 1)
GROUP BY 
    r.r_name, n.n_name
HAVING 
    SUM(hv.total_sale) IS NOT NULL 
    AND COUNT(DISTINCT c.c_custkey) > 0
ORDER BY 
    total_sales_value DESC, customer_count DESC
LIMIT 10
OFFSET 5;