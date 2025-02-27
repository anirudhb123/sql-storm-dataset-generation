WITH SupplierSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
NationSupplierRegion AS (
    SELECT 
        n.n_name,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_name, r.r_name
)
SELECT 
    COALESCE(cs.c_name, 'Unknown Customer') AS customer_name,
    cs.order_count,
    cs.total_spent,
    ss.s_name AS supplier_name,
    ss.total_cost,
    COALESCE(nsr.nation_name, 'Unknown Nation') AS nation_name,
    nsr.supplier_count
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierSummary ss ON cs.order_count > 0
LEFT JOIN 
    (SELECT 
         n.n_name AS nation_name, 
         r.r_name AS region_name, 
         COUNT(DISTINCT s.s_suppkey) AS supplier_count 
     FROM 
         nation n
     JOIN 
         supplier s ON n.n_nationkey = s.s_nationkey
     JOIN 
         region r ON n.n_regionkey = r.r_regionkey
     GROUP BY 
         n.n_name, r.r_name) nsr ON ss.s_name IS NOT NULL
WHERE 
    (cs.total_spent IS NOT NULL AND cs.total_spent > 1000) OR 
    (ss.total_cost IS NULL OR ss.total_cost < 5000)
ORDER BY 
    cs.total_spent DESC NULLS LAST, 
    ss.total_cost ASC NULLS FIRST;
