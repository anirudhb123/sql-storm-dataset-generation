WITH SupplierOrderStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        Coalesce(total_orders, 0) AS total_orders,
        Coalesce(total_revenue, 0) AS total_revenue,
        avg_order_value
    FROM
        supplier s
    LEFT JOIN
        SupplierOrderStats sos ON s.s_suppkey = sos.s_suppkey
),
NationSummary AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        SUM(os.total_revenue) AS nation_revenue,
        COUNT(DISTINCT os.s_suppkey) AS unique_suppliers
    FROM
        nation n
    JOIN
        OrderedSuppliers os ON n.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = os.s_suppkey)
    GROUP BY
        n.n_nationkey, n.n_name
    HAVING
        SUM(os.total_revenue) > 1000000
)
SELECT
    ns.n_name,
    ns.nation_revenue,
    ns.unique_suppliers,
    ROW_NUMBER() OVER (ORDER BY ns.nation_revenue DESC) AS revenue_rank
FROM
    NationSummary ns
WHERE
    ns.unique_suppliers > (SELECT AVG(unique_suppliers) FROM NationSummary)
ORDER BY
    ns.nation_revenue DESC
LIMIT 10;
