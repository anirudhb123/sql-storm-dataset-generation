WITH supplier_info AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(ps.ps_partkey) AS total_parts,
        SUM(ps.ps_availqty) AS total_available,
        STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name
),
order_info AS (
    SELECT
        o.o_orderkey,
        c.c_name AS customer_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_orderkey) AS total_items
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, c.c_name
)
SELECT
    si.s_name AS supplier_name,
    si.nation,
    si.total_parts,
    si.total_available,
    oi.customer_name,
    oi.total_revenue,
    oi.total_items,
    CONCAT(si.part_names, ' | Total Revenue: ', oi.total_revenue) AS detailed_info
FROM
    supplier_info si
JOIN
    order_info oi ON si.total_parts > 0
ORDER BY
    si.total_available DESC, oi.total_revenue DESC;
