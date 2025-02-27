WITH SupplierStats AS (
    SELECT
        s.n_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.n_nationkey
),
NationStats AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_name AS region_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(ss.supplier_count, 0) AS supplier_count
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN
        SupplierStats ss ON n.n_nationkey = ss.n_nationkey
)
SELECT
    ns.n_name,
    ns.region_name,
    ns.total_supply_cost,
    ns.supplier_count
FROM
    NationStats ns
WHERE
    ns.total_supply_cost > (
        SELECT AVG(total_supply_cost) 
        FROM NationStats
    )
ORDER BY
    ns.total_supply_cost DESC
LIMIT 5;
