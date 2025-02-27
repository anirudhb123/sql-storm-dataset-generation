WITH ProductAnalytics AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        AVG(l.l_extendedprice) AS avg_extended_price,
        COUNT(DISTINCT l.l_orderkey) AS total_orders
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name
),
NationCustomer AS (
    SELECT
        n.n_name,
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        n.n_name, c.c_custkey, c.c_name
)
SELECT
    pa.p_partkey,
    pa.p_name,
    pa.total_available_qty,
    pa.avg_supply_cost,
    pa.avg_extended_price,
    pa.total_orders,
    nc.n_name AS nation,
    nc.total_spent
FROM
    ProductAnalytics pa
LEFT JOIN
    NationCustomer nc ON pa.total_orders > 0
ORDER BY
    pa.total_available_qty DESC, nc.total_spent DESC
LIMIT 100;
