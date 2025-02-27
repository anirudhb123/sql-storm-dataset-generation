WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighCostSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        COUNT(DISTINCT rs.s_suppkey) as high_cost_supplier_count
    FROM RankedSuppliers rs
    JOIN region r ON r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
    WHERE rs.rank <= 5
    GROUP BY r.r_name
)
SELECT 
    region_name,
    high_cost_supplier_count
FROM HighCostSuppliers
ORDER BY high_cost_supplier_count DESC;
