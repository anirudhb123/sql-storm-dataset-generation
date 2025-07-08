WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_availqty) AS total_available_quantity,
        AVG(ps.ps_supplycost) AS average_supply_cost,
        RANK() OVER (ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address, s.s_phone
),
TopRegions AS (
    SELECT 
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        (SELECT COUNT(DISTINCT s.s_suppkey) FROM supplier s JOIN nation n ON s.s_nationkey = n.n_nationkey WHERE n.n_regionkey = r.r_regionkey) AS supplier_count
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY 
        r.r_regionkey, r.r_name
)
SELECT 
    tr.r_name AS region_name,
    str.s_name AS supplier_name,
    str.total_available_quantity,
    str.average_supply_cost,
    str.part_count,
    tr.nation_count,
    tr.supplier_count
FROM 
    RankedSuppliers str
JOIN 
    TopRegions tr ON str.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name LIKE '%widget%'))
WHERE 
    str.supplier_rank <= 10
ORDER BY 
    tr.nation_count DESC, str.total_available_quantity DESC;
