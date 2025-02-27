
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_name
),
TotalSupply AS (
    SELECT 
        n.n_name,
        SUM(rs.total_supply_cost) AS aggregate_supply_cost
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
)
SELECT 
    r.r_name AS region_name,
    ts.n_name AS nation_name,
    ts.aggregate_supply_cost
FROM TotalSupply ts
JOIN region r ON ts.n_name IN (SELECT n.n_name FROM nation n WHERE n.n_regionkey = r.r_regionkey)
ORDER BY r.r_name, ts.aggregate_supply_cost DESC;
