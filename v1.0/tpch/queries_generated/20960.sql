WITH RECURSIVE PriceAnalysis AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        p.p_partkey
    UNION ALL
    SELECT 
        pa.p_partkey,
        pa.total_sales * 1.05, 
        pa.order_count + 1
    FROM 
        PriceAnalysis pa
    WHERE 
        pa.total_sales < (SELECT AVG(total_sales) FROM PriceAnalysis) -- limit recursion to average total_sales
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        ps.ps_availqty > 100
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000.00
),
CombinedResults AS (
    SELECT 
        pa.p_partkey,
        pa.total_sales,
        pa.order_count,
        COALESCE(s.s_name, 'No Supplier') AS supplier_name,
        COALESCE(s.s_suppkey, 0) AS supplier_key
    FROM 
        PriceAnalysis pa
    LEFT JOIN 
        HighValueSuppliers s ON pa.p_partkey = s.s_suppkey -- Obscure join—assumed related by key
)
SELECT 
    cr.p_partkey,
    cr.total_sales,
    cr.order_count,
    cr.supplier_name,
    cr.supplier_key,
    CASE 
        WHEN cr.total_sales IS NULL THEN 'No Sales'
        WHEN cr.total_sales > 10000 THEN 'High Sales'
        ELSE 'Low Sales'
    END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY cr.sales_category ORDER BY cr.total_sales DESC) AS sales_rank
FROM 
    CombinedResults cr
ORDER BY 
    sales_category, total_sales DESC
FETCH FIRST 100 ROWS ONLY;
