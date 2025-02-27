WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
),
RegionNation AS (
    SELECT 
        r.r_regionkey,
        n.n_nationkey,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey
)
SELECT 
    s.s_name,
    sc.total_supply_cost,
    c.c_name,
    co.order_count,
    co.total_spent,
    rn.nation_count
FROM 
    SupplierCost sc
JOIN 
    supplier s ON sc.s_suppkey = s.s_suppkey
JOIN 
    CustomerOrders co ON co.c_custkey = (SELECT c.c_custkey FROM customer c ORDER BY c.c_custkey LIMIT 1)
JOIN 
    RegionNation rn ON rn.r_regionkey = (SELECT MIN(r.r_regionkey) FROM region r)
WHERE 
    sc.total_supply_cost > 1000
ORDER BY 
    co.total_spent DESC, sc.total_supply_cost ASC
LIMIT 50;
