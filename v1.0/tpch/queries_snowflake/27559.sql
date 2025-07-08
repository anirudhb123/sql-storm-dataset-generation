
WITH RankedSuppliers AS (
    SELECT
        s.s_name AS supplier_name,
        r.r_name AS region_name,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER(PARTITION BY r.r_name ORDER BY COUNT(DISTINCT ps.ps_partkey) DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY
        s.s_name, r.r_name
),
TopSuppliers AS (
    SELECT
        supplier_name,
        region_name,
        supply_count,
        total_supply_cost
    FROM
        RankedSuppliers
    WHERE
        rn <= 5
)
SELECT
    region_name,
    LISTAGG(supplier_name, ', ') AS top_suppliers,
    SUM(supply_count) AS total_supply,
    SUM(total_supply_cost) AS total_cost
FROM
    TopSuppliers
GROUP BY
    region_name
ORDER BY
    total_cost DESC;
