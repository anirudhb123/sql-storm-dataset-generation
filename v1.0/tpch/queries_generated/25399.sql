WITH SupplierParts AS (
    SELECT
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        REPLACE(LOWER(s.s_comment), ',', '') AS normalized_supplier_comment
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
CustomerOrders AS (
    SELECT
        c.c_name AS customer_name,
        o.o_orderkey AS order_key,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        CONVERT(VARCHAR(20), o.o_orderdate, 101) AS formatted_order_date,
        o.o_comment AS order_comment
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_name, o.o_orderkey, o.o_orderdate, o.o_comment
),
AggregatedData AS (
    SELECT
        sp.supplier_name,
        sp.part_name,
        sp.available_quantity,
        sp.supply_cost,
        co.customer_name,
        co.order_key,
        co.total_order_value,
        co.formatted_order_date,
        SUBSTRING(sp.normalized_supplier_comment, 1, 50) AS short_supplier_comment
    FROM
        SupplierParts sp
    LEFT JOIN
        CustomerOrders co ON sp.available_quantity > 100
)
SELECT
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    customer_name,
    order_key,
    total_order_value,
    formatted_order_date,
    short_supplier_comment
FROM
    AggregatedData
WHERE
    total_order_value > 5000
ORDER BY
    total_order_value DESC, supplier_name ASC;
