WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        MAX(o.o_totalprice) AS max_order_price,
        AVG(o.o_totalprice) AS avg_order_price
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_linenumber) AS total_line_items,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate >= '2023-01-01' AND l.l_shipdate < '2024-01-01'
    GROUP BY
        o.o_orderkey
)
SELECT
    c.c_custkey,
    c.c_name,
    co.total_orders,
    co.max_order_price,
    co.avg_order_price,
    ss.total_available_qty,
    ss.total_cost,
    od.net_revenue,
    od.total_line_items,
    od.unique_suppliers
FROM
    CustomerOrders co
JOIN
    SupplierStats ss ON ss.total_available_qty > 1000
LEFT JOIN
    OrderDetails od ON od.unique_suppliers > 5
JOIN
    customer c ON co.c_custkey = c.c_custkey
WHERE
    c.c_acctbal > 500
ORDER BY
    co.avg_order_price DESC,
    ss.total_cost ASC
LIMIT 100;
