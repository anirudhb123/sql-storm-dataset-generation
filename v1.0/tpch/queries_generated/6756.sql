WITH TotalSales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name
), SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
), MarketSegmentSales AS (
    SELECT
        c.c_mktsegment,
        SUM(o.o_totalprice) AS segment_revenue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_mktsegment
)
SELECT
    r.r_name AS region,
    SUM(ts.total_revenue) AS total_part_revenue,
    SI.total_supply_cost,
    COALESCE(MS.segment_revenue, 0) AS total_segment_revenue
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    SupplierInfo SI ON s.s_suppkey = SI.s_suppkey
LEFT JOIN
    TotalSales ts ON ts.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = s.s_suppkey)
LEFT JOIN
    MarketSegmentSales MS ON MS.c_mktsegment = 'BUILDING'
GROUP BY
    r.r_name, SI.total_supply_cost
ORDER BY
    total_part_revenue DESC, r.r_name;
