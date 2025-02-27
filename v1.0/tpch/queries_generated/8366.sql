WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_name
),
SalesStats AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    r.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.order_count, 0) AS order_count
FROM 
    RegionStats rs
LEFT JOIN 
    SalesStats ss ON rs.nation_count = (SELECT COUNT(*) FROM nation WHERE n_regionkey = (SELECT r_regionkey FROM region WHERE r_name = rs.region_name))
ORDER BY 
    rs.region_name;
