WITH RegionalStats AS (
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
OrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        c.c_nationkey
)
SELECT 
    rs.region_name,
    rs.nation_count,
    rs.total_supplier_balance,
    os.total_orders,
    os.total_revenue
FROM 
    RegionalStats rs
LEFT JOIN 
    OrderStats os ON rs.nation_count = 
        (SELECT COUNT(DISTINCT n2.n_nationkey) 
         FROM nation n2 
         WHERE n2.n_regionkey = rs.region_name)
ORDER BY 
    rs.region_name;
