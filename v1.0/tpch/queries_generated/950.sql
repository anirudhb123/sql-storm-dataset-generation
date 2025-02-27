WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
OrderStats AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        ROW_NUMBER() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    ns.n_name AS nation_name,
    COUNT(DISTINCT os.o_orderkey) AS total_orders,
    SUM(os.total_order_value) AS total_order_value,
    COUNT(DISTINCT ss.s_suppkey) AS unique_suppliers,
    SUM(ss.total_supply_cost) AS total_supplier_cost
FROM
    nation ns
LEFT JOIN
    supplier s ON ns.n_nationkey = s.s_nationkey
LEFT JOIN
    SupplierStats ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN
    OrderStats os ON ss.s_suppkey = s.s_suppkey
GROUP BY
    ns.n_name
HAVING
    COUNT(DISTINCT os.o_orderkey) > 5
ORDER BY
    total_order_value DESC;
