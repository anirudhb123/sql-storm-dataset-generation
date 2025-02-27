WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name,
        rs.s_name,
        rs.total_cost
    FROM RankedSuppliers rs
    JOIN region r ON rs.rank = 1 AND r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_name = rs.nation_name)
)
SELECT 
    ts.region_name,
    COUNT(DISTINCT ts.s_name) AS unique_suppliers,
    SUM(ts.total_cost) AS aggregate_cost
FROM TopSuppliers ts
GROUP BY ts.region_name
ORDER BY aggregate_cost DESC;
