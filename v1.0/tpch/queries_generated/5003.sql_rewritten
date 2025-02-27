WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rnk
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    ORDER BY
        total_supply_cost DESC
    LIMIT 10
),
OrderDetails AS (
    SELECT
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM
        lineitem lo
    GROUP BY
        lo.l_orderkey
)
SELECT
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_totalprice,
    ro.o_orderdate,
    ro.o_orderpriority,
    od.total_revenue,
    ts.s_name AS top_supplier
FROM
    RankedOrders ro
JOIN
    OrderDetails od ON ro.o_orderkey = od.l_orderkey
JOIN
    TopSuppliers ts ON od.l_orderkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
WHERE
    ro.rnk <= 5
ORDER BY
    ro.o_orderdate DESC, ro.o_totalprice ASC;