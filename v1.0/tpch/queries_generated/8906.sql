WITH RegionCounts AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_name
),
SupplierStats AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_account_balance,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        n.n_name
),
OrderSummaries AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rc.region_name,
    rc.nation_count,
    ss.nation_name,
    ss.total_account_balance,
    ss.supplier_count,
    os.total_order_value,
    os.order_count
FROM 
    RegionCounts rc
JOIN 
    nation n ON n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = rc.region_name)
JOIN 
    SupplierStats ss ON ss.nation_name = n.n_name
LEFT JOIN 
    OrderSummaries os ON os.c_nationkey = n.n_nationkey
ORDER BY 
    rc.region_name, ss.nation_name;
