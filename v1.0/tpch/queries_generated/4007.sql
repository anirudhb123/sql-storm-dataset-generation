WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        l.l_shipdate >= DATE '2023-01-01'
    GROUP BY
        n.n_name, r.r_name
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
QualifiedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ps.part_count,
        ps.total_supply_cost
    FROM
        supplier s
    JOIN
        SupplierParts ps ON s.s_suppkey = ps.s_suppkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
        AND ps.part_count > 10
)
SELECT
    r.nation_name,
    r.region_name,
    COALESCE(SUM(s.total_sales), 0) AS total_sales,
    COALESCE(SUM(q.total_supply_cost), 0) AS total_supply_cost
FROM
    RegionalSales r
FULL OUTER JOIN
    QualifiedSuppliers q ON r.region_name = 'Some Region Name' -- Replace with actual logic as needed
LEFT JOIN
    (SELECT DISTINCT s.s_suppkey, s.s_name, ps.total_supply_cost
     FROM supplier s
     JOIN SupplierParts ps ON s.s_suppkey = ps.s_suppkey) s
ON q.s_suppkey = s.s_suppkey
GROUP BY
    r.nation_name, r.region_name
HAVING
    SUM(s.total_supply_cost) IS NOT NULL
ORDER BY
    total_sales DESC, total_supply_cost DESC;
