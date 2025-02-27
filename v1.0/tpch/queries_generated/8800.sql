WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
FilteredSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        rs.s_name, 
        rs.total_supply_cost
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.nation_name = n.n_name
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    fs.region_name,
    COUNT(DISTINCT fs.s_name) AS top_suppliers_count,
    SUM(fs.total_supply_cost) AS aggregated_cost
FROM 
    FilteredSuppliers fs
JOIN 
    orders o ON EXISTS (
        SELECT 1 
        FROM lineitem l 
        WHERE l.l_orderkey = o.o_orderkey 
        AND l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_name = fs.s_name))
    )
WHERE 
    o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY 
    fs.region_name
ORDER BY 
    aggregated_cost DESC;
