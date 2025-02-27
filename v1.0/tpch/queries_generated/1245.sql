WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS distinct_parts_supplied
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts_ordered
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '2023-01-01'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
NationSummary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
        SUM(CASE WHEN c.c_acctbal IS NULL THEN 0 ELSE c.c_acctbal END) AS total_balances
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    GROUP BY
        n.n_nationkey, n.n_name
)
SELECT
    n.n_name AS nation_name,
    ss.s_name AS supplier_name,
    os.total_order_value AS order_value,
    ss.total_avail_qty AS supplier_avail_qty,
    ss.avg_supply_cost AS supplier_avg_cost,
    ns.total_suppliers,
    ns.total_balances
FROM
    SupplierStats ss
JOIN
    OrderStats os ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_shipdate <= CURRENT_DATE AND l.l_returnflag = 'R'
    )
JOIN
    NationSummary ns ON ss.s_suppkey IN (
        SELECT s.s_suppkey
        FROM supplier s
        WHERE s.s_nationkey = (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_name LIKE 'N%'
            LIMIT 1
        )
    )
WHERE
    os.total_order_value > (
        SELECT AVG(total_order_value) FROM OrderStats
    )
ORDER BY
    os.total_order_value DESC;
