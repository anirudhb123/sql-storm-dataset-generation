
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 10000
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
NationSummary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM
        nation n
    LEFT JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    n.n_name,
    ns.total_customers,
    ns.avg_supplier_balance,
    COALESCE((
        SELECT
            SUM(hv.total_order_value)
        FROM
            HighValueOrders hv
        JOIN
            lineitem li ON hv.o_orderkey = li.l_orderkey
        WHERE
            li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1998-01-01'
    ), 0) AS total_high_value_sales
FROM
    NationSummary ns
JOIN
    nation n ON ns.n_nationkey = n.n_nationkey
LEFT JOIN
    RankedSuppliers rs ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = rs.s_suppkey LIMIT 1)
WHERE
    ns.avg_supplier_balance IS NOT NULL
ORDER BY
    total_high_value_sales DESC;
