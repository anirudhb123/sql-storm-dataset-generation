WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS row_num
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' AND
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    si.s_name,
    si.nation_name,
    os.o_orderkey,
    os.total_sales,
    os.supplier_count
FROM 
    SupplierInfo si
LEFT JOIN 
    OrderSummary os ON si.row_num = os.supplier_count
WHERE 
    si.row_num <= 5
ORDER BY 
    si.nation_name, os.total_sales DESC
UNION ALL
SELECT 
    'Total' AS s_name,
    NULL AS nation_name,
    NULL AS o_orderkey,
    SUM(total_sales) AS total_sales,
    COUNT(DISTINCT o_orderkey) AS supplier_count
FROM 
    OrderSummary
WHERE 
    total_sales IS NOT NULL;
