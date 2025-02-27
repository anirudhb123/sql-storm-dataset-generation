WITH RECURSIVE order_totals AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
supplier_stats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
nation_region AS (
    SELECT
        n.n_nationkey,
        r.r_regionkey,
        r.r_name
    FROM
        nation n
    LEFT JOIN 
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    n.r_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(ot.total_price) AS total_order_value,
    AVG(ss.avg_supply_cost) AS avg_supplier_cost,
    MAX(ss.part_count) AS max_parts_supplied
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    order_totals ot ON o.o_orderkey = ot.o_orderkey
JOIN
    supplier_stats ss ON ss.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1))
JOIN
    nation_region n ON c.c_nationkey = n.n_nationkey
WHERE
    n.r_name IS NOT NULL
GROUP BY
    n.r_name
HAVING
    SUM(ot.total_price) > 1000.00
ORDER BY
    total_order_value DESC;
