WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), RankedSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_supply_cost,
        sp.part_count,
        RANK() OVER (ORDER BY sp.total_supply_cost DESC) AS supplier_rank
    FROM 
        SupplierPerformance sp
)

SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT CONCAT(DISTINCT s.s_name, ': $', CAST(sp.total_supply_cost AS VARCHAR)), '; ') AS supplier_list
FROM 
    customer c
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    RankedSuppliers sp ON sp.s_suppkey IN (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey 
        WHERE p.p_size >= 10
    )
GROUP BY 
    n.n_name, r.r_name
HAVING 
    AVG(o.o_totalprice) IS NOT NULL 
    OR COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    customer_count DESC, region_name;
