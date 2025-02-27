WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
RegionOverview AS (
    SELECT
        r.r_name,
        COUNT(DISTINCT ns.n_nationkey) AS nation_count,
        SUM(s.s_acctbal) AS total_supplier_balance
    FROM
        region r
    JOIN
        nation ns ON r.r_regionkey = ns.n_regionkey
    JOIN
        supplier s ON ns.n_nationkey = s.s_nationkey
    GROUP BY
        r.r_name
)
SELECT
    ro.r_name AS region,
    ro.nation_count,
    ro.total_supplier_balance,
    rs.s_name AS top_supplier,
    rs.total_cost
FROM
    RegionOverview ro
JOIN
    RankedSuppliers rs ON ro.region = rs.nation_count
WHERE
    rs.rank_in_region = 1
ORDER BY
    ro.total_supplier_balance DESC, ro.region;
