WITH CustomerSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartCounts AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cs.total_sales,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer c ON c.c_custkey = cs.c_custkey
    WHERE 
        cs.total_sales > 1000
),
SupplierRegion AS (
    SELECT 
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    tc.c_name AS customer_name,
    tc.total_sales,
    sr.region_name,
    COUNT(DISTINCT spc.part_count) AS unique_parts,
    MAX(spc.part_count) AS max_parts_by_supplier
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierPartCounts spc ON spc.part_count > 5
LEFT JOIN 
    SupplierRegion sr ON spc.part_count IS NOT NULL
WHERE 
    sr.region_name IS NOT NULL OR tc.total_sales IS NULL
GROUP BY 
    tc.c_name, tc.total_sales, sr.region_name
ORDER BY 
    tc.total_sales DESC, customer_name ASC;
