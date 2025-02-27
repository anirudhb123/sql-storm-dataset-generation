WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rn,
        COUNT(p.ps_partkey) AS part_count
    FROM 
        supplier s
    LEFT JOIN 
        partsupp p ON s.s_suppkey = p.ps_suppkey
    WHERE 
        s.s_acctbal > 5000
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal
    FROM 
        SupplierStats s
    WHERE 
        s.rn <= 5
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS unique_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_regionkey,
    r.r_name,
    SUM(COALESCE(ds.total_sales, 0)) AS total_sales_by_region,
    AVG(s.s_acctbal) AS avg_supplier_acctbal,
    MAX(s.part_count) AS max_parts_supply
FROM 
    region r
LEFT JOIN 
    TopSuppliers s ON r.r_regionkey = s.s_suppkey -- Assuming s_suppkey correlates with region for illustrative purposes
LEFT JOIN 
    OrderDetails ds ON ds.o_orderkey = s.s_suppkey
GROUP BY 
    r.r_regionkey, r.r_name
HAVING 
    SUM(COALESCE(ds.total_sales, 0)) > 10000
ORDER BY 
    total_sales_by_region DESC;
