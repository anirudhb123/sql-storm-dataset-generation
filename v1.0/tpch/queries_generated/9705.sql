WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RegionNation AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY 
        r.r_name, n.n_name
)
SELECT 
    co.c_name,
    co.total_spent,
    co.order_count,
    sp.s_name,
    sp.total_supply_cost,
    rn.region_name,
    rn.nation_name,
    rn.customer_count
FROM 
    CustomerOrders co
JOIN 
    SupplierParts sp ON co.total_spent > 1000
JOIN 
    RegionNation rn ON rn.customer_count > 50
ORDER BY 
    co.total_spent DESC, sp.total_supply_cost ASC
LIMIT 10;
