WITH part_summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_mfgr,
        p.p_type,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names,
        STRING_AGG(DISTINCT c.c_name, ', ') AS customer_names
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN 
        orders o ON EXISTS (
            SELECT 1
            FROM lineitem l 
            WHERE l.l_orderkey = o.o_orderkey AND l.l_partkey = p.p_partkey
        )
    LEFT JOIN 
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_mfgr, p.p_type, r.r_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    p.p_type,
    ps.supplier_count,
    ps.total_available_quantity,
    ps.average_supply_cost,
    ps.supplier_names,
    ps.customer_names
FROM 
    part_summary ps
JOIN 
    part p ON ps.p_partkey = p.p_partkey
ORDER BY 
    ps.total_available_quantity DESC,
    ps.average_supply_cost ASC;
