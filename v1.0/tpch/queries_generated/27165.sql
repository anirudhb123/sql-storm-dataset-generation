WITH PartSummary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        GROUP_CONCAT(DISTINCT s.s_name) AS suppliers
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RegionDetails AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        GROUP_CONCAT(DISTINCT n.n_name) AS nations
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    p.p_name,
    p.total_available,
    p.avg_supply_cost,
    p.supplier_count,
    p.suppliers,
    c.c_name,
    c.order_count,
    c.total_spent,
    r.r_name,
    r.nation_count,
    r.nations
FROM 
    PartSummary p
LEFT JOIN 
    CustomerOrders c ON p.supplier_count > 0
LEFT JOIN 
    RegionDetails r ON r.nation_count > 0
WHERE 
    p.total_available > 100
ORDER BY 
    p.avg_supply_cost DESC, 
    c.total_spent DESC;
