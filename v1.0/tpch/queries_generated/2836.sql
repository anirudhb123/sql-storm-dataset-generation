WITH SupplierParts AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
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
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
OrderLineDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_item_count
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
)
SELECT
    cp.c_name,
    cp.total_orders,
    cp.total_spent,
    sp.s_name AS supplier_name,
    sp.total_supply_value,
    CASE
        WHEN ol.total_revenue IS NULL THEN 0
        ELSE ol.total_revenue
    END AS order_revenue,
    RANK() OVER (PARTITION BY cp.c_custkey ORDER BY ol.line_item_count DESC) AS revenue_rank
FROM
    CustomerOrders cp
LEFT JOIN
    OrderLineDetails ol ON cp.total_orders > 0
LEFT JOIN
    SupplierParts sp ON sp.total_supply_value > 10000
WHERE
    cp.total_spent > 5000
    AND (sp.total_supply_value IS NOT NULL OR cp.total_orders > 5)
ORDER BY
    cp.total_spent DESC,
    sp.total_supply_value ASC;
