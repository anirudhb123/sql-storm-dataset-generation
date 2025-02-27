WITH SupplierPartDetails AS (
    SELECT 
        ps.ps_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        s.s_acctbal,
        ps.ps_availqty,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        n.n_name AS nation_name,
        SUM(s.s_acctbal) AS total_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        s.s_acctbal > 100000
    GROUP BY 
        r.r_name, n.n_name
),
ProductStats AS (
    SELECT 
        p.p_type,
        COUNT(DISTINCT ps.ps_partkey) AS supplier_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        MAX(ps.ps_availqty) AS max_avail_qty
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        p.p_type
)
SELECT 
    r.region_name,
    n.nation_name,
    ps.p_type,
    ps.supplier_count,
    ps.avg_supply_cost,
    ps.max_avail_qty,
    SUM(COALESCE(d.ps_supplycost, 0)) AS total_supply_cost
FROM 
    HighValueSuppliers hvs
JOIN 
    SupplierPartDetails d ON d.rank <= 5
JOIN 
    ProductStats ps ON ps.supplier_count > 0
JOIN 
    nation n ON n.n_name = hvs.nation_name
JOIN 
    region r ON r.r_name = hvs.region_name
GROUP BY 
    r.region_name, n.nation_name, ps.p_type, ps.supplier_count, ps.avg_supply_cost, ps.max_avail_qty
ORDER BY 
    r.region_name, n.nation_name, ps.p_type;
