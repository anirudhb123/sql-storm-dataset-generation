
WITH SupplierPartDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
NationRegionInfo AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
TopSuppliers AS (
    SELECT 
        s.p_name,
        sp.s_suppkey,
        sp.s_name,
        sp.total_available,
        sp.total_supply_cost,
        nri.r_name
    FROM 
        SupplierPartDetails sp
    JOIN 
        partsupp ps ON sp.s_suppkey = ps.ps_suppkey
    JOIN 
        part s ON ps.ps_partkey = s.p_partkey
    JOIN 
        NationRegionInfo nri ON sp.s_suppkey = (
            SELECT s2.s_suppkey 
            FROM supplier s2 
            JOIN partsupp ps2 ON s2.s_suppkey = ps2.ps_suppkey 
            WHERE ps2.ps_partkey = ps.ps_partkey 
            ORDER BY ps2.ps_supplycost DESC 
            LIMIT 1
        )
    WHERE 
        sp.total_available > 0
    ORDER BY 
        sp.total_supply_cost DESC
    LIMIT 10
)
SELECT 
    t.p_name,
    t.s_suppkey,
    t.s_name,
    t.total_available,
    t.total_supply_cost,
    r.r_name
FROM 
    TopSuppliers t
JOIN 
    NationRegionInfo r ON t.r_name = r.r_name;
