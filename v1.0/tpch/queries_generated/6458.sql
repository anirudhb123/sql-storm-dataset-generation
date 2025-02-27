WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM
        RankedOrders ro
    WHERE
        ro.order_rank <= 5
),
LineItemDetails AS (
    SELECT
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(lo.l_orderkey) AS lineitem_count
    FROM
        lineitem lo
    GROUP BY
        lo.l_orderkey
)
SELECT
    to.o_orderkey,
    to.o_orderdate,
    to.c_name,
    lod.revenue,
    lod.lineitem_count
FROM
    TopOrders to
JOIN
    LineItemDetails lod ON to.o_orderkey = lod.l_orderkey
ORDER BY
    to.o_orderdate DESC,
    lod.revenue DESC;
