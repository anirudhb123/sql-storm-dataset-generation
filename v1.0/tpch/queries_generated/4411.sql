WITH supplier_stats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_items
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2023-01-01'
    GROUP BY
        o.o_orderkey, o.o_custkey
),
nation_region AS (
    SELECT
        n.n_nationkey,
        n.n_name,
        r.r_regionkey,
        r.r_name
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    ns.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS orders_count,
    AVG(os.total_revenue) AS avg_order_revenue,
    MAX(ss.total_available_qty) AS max_available_qty,
    STRING_AGG(DISTINCT CONCAT(s.s_name, ': ', ss.avg_supply_cost), '; ') AS supplier_details
FROM
    order_summary os
JOIN
    customer c ON os.o_custkey = c.c_custkey
JOIN
    nation_region nr ON c.c_nationkey = nr.n_nationkey
LEFT OUTER JOIN
    supplier_stats ss ON os.o_custkey = ss.s_suppkey
    AND os.total_items > 5
WHERE
    (ss.total_available_qty IS NULL OR ss.avg_supply_cost < 20)
GROUP BY
    ns.n_name
ORDER BY
    orders_count DESC;
