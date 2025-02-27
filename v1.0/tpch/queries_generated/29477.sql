WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_by_supply
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
HighValueSuppliers AS (
    SELECT 
        r.r_name,
        COUNT(rs.s_suppkey) AS supplier_count,
        SUM(rs.total_supply_value) AS total_region_supply_value
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rank_by_supply <= 5
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    r.supplier_count,
    r.total_region_supply_value,
    CONCAT('Total suppliers in ', r.r_name, ': ', r.supplier_count, ', Total supply value: $', FORMAT(r.total_region_supply_value, 2)) AS report
FROM HighValueSuppliers r
ORDER BY r.total_region_supply_value DESC;
