WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighAvailabilitySuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        rs.total_available,
        rs.total_cost,
        n.n_name AS nation_name
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    WHERE
        rs.rn <= 5
),
OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate > '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    has.s_name AS supplier_name,
    has.nation_name,
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue
FROM
    HighAvailabilitySuppliers has
JOIN
    OrderSummary os ON has.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey = os.o_orderkey
    )
ORDER BY
    has.nation_name, os.total_revenue DESC;
