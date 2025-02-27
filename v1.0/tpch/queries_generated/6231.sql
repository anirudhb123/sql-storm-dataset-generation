WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '2022-01-01'
        AND o.o_orderdate < DATE '2023-01-01'
    GROUP BY
        s.s_suppkey
),
RegionDetails AS (
    SELECT
        r.r_regionkey,
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    GROUP BY
        r.r_regionkey, r.r_name
)
SELECT
    r.r_name,
    SUM(ss.total_cost) AS total_supplier_cost,
    SUM(ss.order_count) AS total_orders,
    rd.nation_count
FROM
    SupplierStats ss
JOIN
    supplier s ON ss.s_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    RegionDetails rd ON n.n_regionkey = rd.r_regionkey
GROUP BY
    r.r_name, rd.nation_count
ORDER BY
    total_supplier_cost DESC, total_orders DESC
LIMIT 10;
