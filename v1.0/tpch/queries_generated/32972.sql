WITH RECURSIVE CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal IS NOT NULL AND c.c_acctbal > 0
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, ps.ps_partkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_regionkey, r.r_name
    HAVING 
        COUNT(DISTINCT s.s_suppkey) > 10
)
SELECT 
    cus.c_name,
    cus.total_spent,
    cus.total_orders,
    spr.s_name,
    spr.total_available,
    spr.avg_supply_cost,
    rg.r_name,
    rg.total_suppliers
FROM 
    CustomerOrderSummary AS cus
LEFT JOIN 
    SupplierPartDetails AS spr ON spr.total_available < (SELECT AVG(total_available) FROM SupplierPartDetails)
JOIN 
    TopRegions AS rg ON spr.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 10))
WHERE 
    cus.rn = 1
ORDER BY 
    cus.total_spent DESC, rg.total_suppliers DESC
LIMIT 100;
