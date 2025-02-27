WITH RegionStats AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(CASE WHEN s.s_acctbal > 10000 THEN 1 ELSE 0 END) AS wealthy_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(c.c_acctbal) AS average_account_balance
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
PartStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    r.region_name,
    rs.nation_count,
    rs.wealthy_suppliers,
    cs.order_count,
    cs.average_account_balance,
    ps.total_available_qty,
    ps.average_supply_cost
FROM 
    RegionStats rs
JOIN 
    nation n ON rs.nation_count = (SELECT COUNT(*) FROM nation WHERE n.regionkey = rs.region_name)
JOIN 
    CustomerStats cs ON n.n_nationkey = cs.c_nationkey
JOIN 
    PartStats ps ON ps.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 20000)
ORDER BY 
    r.region_name, cs.order_count DESC;
