WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        SUM(sd.total_supply_cost) AS total_supply_cost_region
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierDetails sd ON n.n_nationkey = sd.s_nationkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    rs.r_name AS region_name,
    cs.total_orders,
    cs.total_spent,
    rs.nation_count,
    rs.total_supply_cost_region
FROM 
    CustomerOrders cs
JOIN 
    nation n ON cs.c_nationkey = n.n_nationkey
JOIN 
    RegionSummary rs ON n.n_regionkey = rs.r_regionkey
WHERE 
    cs.total_spent > 5000
ORDER BY 
    total_spent DESC
LIMIT 10;
