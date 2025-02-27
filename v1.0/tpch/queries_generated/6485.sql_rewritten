WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
FinalStats AS (
    SELECT
        s.nation,
        COUNT(DISTINCT os.o_orderkey) AS order_count,
        SUM(os.total_revenue) AS total_revenue,
        SUM(s.total_cost) AS supplier_cost,
        SUM(os.total_quantity) AS total_units
    FROM
        SupplierStats s
    JOIN
        OrderStats os ON s.s_suppkey IN (
            SELECT ps.ps_suppkey
            FROM partsupp ps
            JOIN part p ON ps.ps_partkey = p.p_partkey
            WHERE p.p_type LIKE '%BRASS%'
        )
    GROUP BY
        s.nation
)
SELECT
    nation,
    order_count,
    total_revenue,
    supplier_cost,
    total_units,
    (total_revenue - supplier_cost) AS profit_margin
FROM
    FinalStats
ORDER BY
    profit_margin DESC
LIMIT 10;