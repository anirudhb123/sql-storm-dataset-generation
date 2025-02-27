WITH RECURSIVE supplier_prices AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey,
        s.s_nationkey
),
qualified_suppliers AS (
    SELECT
        sp.s_suppkey,
        sp.total_supply_cost
    FROM
        supplier_prices sp
    WHERE
        sp.rn <= 5
),
order_summaries AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_orderkey) OVER (PARTITION BY o.o_orderstatus) AS order_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '2022-01-01'
    GROUP BY
        o.o_orderkey
),
final_results AS (
    SELECT
        ns.n_name AS nation_name,
        SUM(os.total_order_value) AS total_value,
        COUNT(os.o_orderkey) AS total_orders,
        MAX(sp.total_supply_cost) AS highest_supply_cost
    FROM
        nation ns
    LEFT JOIN
        qualified_suppliers qs ON ns.n_nationkey = (SELECT s_nationkey FROM supplier WHERE s_suppkey = qs.s_suppkey)
    LEFT JOIN
        order_summaries os ON os.o_orderkey IN (
            SELECT o.o_orderkey
            FROM orders o
            WHERE o.o_custkey IN (
                SELECT c.c_custkey
                FROM customer c
                WHERE c.c_nationkey = ns.n_nationkey
            )
        )
    GROUP BY
        ns.n_name
)
SELECT 
    fr.nation_name,
    COALESCE(fr.total_value, 0) AS total_order_value,
    COALESCE(fr.total_orders, 0) AS total_order_count,
    COALESCE(fr.highest_supply_cost, 0.00) AS highest_supply_cost
FROM 
    final_results fr
WHERE 
    fr.highest_supply_cost IS NOT NULL
ORDER BY 
    fr.total_value DESC NULLS LAST;
