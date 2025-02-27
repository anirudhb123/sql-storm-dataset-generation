WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionSummary AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)

SELECT 
    r.r_name AS region_name,
    s.s_name AS supplier_name,
    COALESCE(cs.total_orders, 0) AS customer_orders,
    COALESCE(cs.total_spent, 0) AS total_spent,
    ss.unique_parts_supplied,
    ss.total_supply_value,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY ss.total_supply_value DESC) AS rank
FROM 
    region r
LEFT JOIN 
    nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    CustomerOrders cs ON cs.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        WHERE c.c_nationkey = n.n_nationkey 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = s.s_suppkey
WHERE 
    ss.total_supply_value > (SELECT AVG(total_supply_value) FROM SupplierStats)
ORDER BY 
    r.r_name, ss.total_supply_value DESC;
