WITH OrderSummary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
SupplierInfo AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT
        si.s_suppkey,
        si.s_name,
        si.total_cost,
        RANK() OVER (ORDER BY si.total_cost DESC) AS supplier_rank
    FROM
        SupplierInfo si
)
SELECT
    os.o_orderkey,
    os.o_orderdate,
    os.total_revenue,
    ts.s_name,
    ts.total_cost
FROM
    OrderSummary os
LEFT JOIN
    TopSuppliers ts ON os.unique_suppliers = ts.s_suppkey
WHERE
    NOT EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = os.o_orderkey
        AND l.l_returnflag = 'Y'
    ) OR os.total_revenue IS NULL
ORDER BY
    os.total_revenue DESC,
    ts.total_cost ASC
LIMIT 100
UNION ALL
SELECT
    NULL AS o_orderkey,
    NULL AS o_orderdate,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    'Total' AS s_name,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
FROM
    lineitem l
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
WHERE
    l.l_shipdate >= '1996-01-01' AND l.l_shipdate < '1997-01-01'
GROUP BY
    ROLLUP (l.l_shipdate)
HAVING
    SUM(l.l_discount) IS NULL OR total_revenue > 10000.00;
