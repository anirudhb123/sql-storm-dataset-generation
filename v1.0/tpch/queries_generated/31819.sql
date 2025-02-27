WITH RECURSIVE RankedSales AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_custkey
),
TopCustomers AS (
    SELECT 
        r.r_name AS region_name,
        ns.n_name AS nation_name,
        rs.c_name,
        rs.total_sales
    FROM 
        RankedSales rs
    JOIN 
        nation ns ON rs.c_custkey = ns.n_nationkey
    JOIN 
        region r ON ns.n_regionkey = r.r_regionkey
    WHERE 
        rs.sales_rank <= 5
),
SupplierAvailability AS (
    SELECT 
        p.p_partkey,
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, s.s_suppkey
),
FinalReport AS (
    SELECT 
        tc.region_name,
        tc.nation_name,
        tc.c_name,
        tc.total_sales,
        sa.total_available,
        CASE 
            WHEN sa.total_available > 100 THEN 'Sufficient Stock'
            WHEN sa.total_available IS NULL THEN 'No Availability Data'
            ELSE 'Low Stock'
        END AS stock_status
    FROM 
        TopCustomers tc
    LEFT JOIN 
        SupplierAvailability sa ON tc.c_name = sa.p_partkey
)
SELECT 
    region_name,
    nation_name,
    c_name,
    total_sales,
    COALESCE(total_available, 0) AS total_available,
    stock_status
FROM 
    FinalReport
ORDER BY 
    region_name, total_sales DESC;
