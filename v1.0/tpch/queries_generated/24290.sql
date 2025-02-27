WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_orderstatus IN ('O', 'F')
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        s.s_name,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_cost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_name
),
CustomerCounts AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
    HAVING
        COUNT(o.o_orderkey) > 3
),
FilteredLineItems AS (
    SELECT
        l.l_orderkey,
        SUM(LENGTH(l.l_comment) - LENGTH(REPLACE(l.l_comment, 'bad', ''))) AS bad_comment_count
    FROM
        lineitem l
    WHERE
        l.l_returnflag IS NULL
    GROUP BY
        l.l_orderkey
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    sp.s_name,
    sp.total_cost,
    cc.order_count,
    fli.bad_comment_count,
    CASE
        WHEN fli.bad_comment_count IS NULL THEN 'No Bad Comments'
        WHEN fli.bad_comment_count > 0 THEN 'Contains Bad Comments'
        ELSE 'Unknown'
    END AS comment_status
FROM
    RankedOrders ro
LEFT JOIN
    SupplierParts sp ON ro.o_orderkey = sp.ps_partkey
JOIN
    CustomerCounts cc ON ro.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = cc.c_custkey)
LEFT JOIN
    FilteredLineItems fli ON ro.o_orderkey = fli.l_orderkey
WHERE
    ro.rn <= 5
ORDER BY
    ro.o_orderdate ASC,
    ro.o_totalprice DESC
LIMIT 100;
