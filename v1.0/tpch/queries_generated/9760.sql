WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_order
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2023-10-01'
),
top_orders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM
        ranked_orders ro
    WHERE
        ro.rank_order <= 5
),
part_supplier_stats AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        ps.ps_partkey
),
order_lineitem_summary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
)
SELECT
    to.o_orderkey,
    to.o_orderdate,
    to.o_totalprice,
    to.c_name,
    pls.total_avail_qty,
    pls.avg_cost,
    ols.total_revenue
FROM
    top_orders to
LEFT JOIN
    part_supplier_stats pls ON pls.ps_partkey IN (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = to.o_orderkey)
LEFT JOIN
    order_lineitem_summary ols ON ols.l_orderkey = to.o_orderkey
ORDER BY
    to.o_orderdate DESC, to.o_orderkey;
