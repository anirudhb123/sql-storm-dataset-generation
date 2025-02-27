WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        r.r_regionkey, r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_sales 
    FROM 
        RegionalSales 
    WHERE 
        sales_rank <= 5
),
SupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_account_balance
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)
SELECT 
    tr.region_name,
    tr.total_sales,
    ss.nation_name,
    ss.supplier_count,
    ss.avg_account_balance,
    COALESCE(tr.total_sales / NULLIF(ss.supplier_count, 0), 0) AS sales_per_supplier
FROM 
    TopRegions tr
LEFT JOIN 
    SupplierStats ss ON ss.nation_name = (
        SELECT n.n_name 
        FROM nation n 
        WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = tr.region_name)
        LIMIT 1
    )
ORDER BY 
    tr.total_sales DESC, ss.nation_name;
