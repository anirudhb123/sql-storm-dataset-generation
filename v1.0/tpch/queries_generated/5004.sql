WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
TopRevenueOrders AS (
    SELECT
        r.o_orderkey,
        r.o_orderdate,
        r.total_revenue
    FROM
        RankedOrders r
    WHERE
        r.revenue_rank <= 10
),
SupplierPartDetails AS (
    SELECT
        ps.ps_partkey,
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
)
SELECT
    t.o_orderkey,
    t.o_orderdate,
    t.total_revenue,
    spd.supplier_name,
    spd.part_name,
    spd.ps_supplycost
FROM
    TopRevenueOrders t
JOIN
    SupplierPartDetails spd ON spd.ps_partkey IN (
        SELECT
            l.l_partkey
        FROM
            lineitem l
        JOIN
            orders o ON l.l_orderkey = o.o_orderkey
        WHERE
            o.o_orderkey = t.o_orderkey
    )
ORDER BY
    t.o_orderdate DESC, t.total_revenue DESC;
