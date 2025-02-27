WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
CustomerSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_cost
    FROM
        supplier s
    INNER JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
LineItemsSummary AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(DISTINCT l.l_linenumber) AS item_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM
        lineitem l
    WHERE
        l.l_shipdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY
        l.l_orderkey
)
SELECT
    cs.c_name,
    cs.total_spent,
    cs.order_count,
    rp.o_orderkey,
    rp.o_orderdate,
    rp.o_totalprice,
    rp.o_orderstatus,
    rp.o_shippriority,
    COALESCE(lis.net_revenue, 0) AS net_revenue,
    COALESCE(lis.item_count, 0) AS item_count,
    COALESCE(lis.avg_quantity, 0) AS avg_quantity,
    sp.s_name,
    sp.total_available,
    sp.avg_cost
FROM
    CustomerSummary cs
LEFT JOIN
    RankedOrders rp ON cs.custkey = rp.o_custkey
LEFT JOIN
    LineItemsSummary lis ON rp.o_orderkey = lis.l_orderkey
INNER JOIN
    SupplierPerformance sp ON sp.avg_cost < (SELECT AVG(ps_supplycost) FROM partsupp)
WHERE
    cs.total_spent > 1000
AND
    rp.order_rank <= 10
ORDER BY
    cs.total_spent DESC, rp.o_orderdate ASC;
