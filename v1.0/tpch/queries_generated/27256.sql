WITH supplier_part_details AS (
    SELECT
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_availqty AS available_quantity,
        ps.ps_supplycost AS supply_cost,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' with available quantity: ', CAST(ps.ps_availqty AS VARCHAR), ' and supply cost: $', CAST(ps.ps_supplycost AS VARCHAR(12))) AS details
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
),
customer_order_summary AS (
    SELECT
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        CONCAT(c.c_name, ' has placed ', COUNT(o.o_orderkey), ' orders totaling $', CAST(SUM(o.o_totalprice) AS VARCHAR(12))) AS summary
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_name
),
final_benchmark AS (
    SELECT
        spd.supplier_name,
        spd.part_name,
        spd.available_quantity,
        spd.supply_cost,
        cs.customer_name,
        cs.total_orders,
        cs.total_spent,
        CONCAT(spd.details, '; ', cs.summary) AS benchmark_summary
    FROM
        supplier_part_details spd
    JOIN
        customer_order_summary cs ON TRUE
)
SELECT
    supplier_name,
    part_name,
    available_quantity,
    supply_cost,
    customer_name,
    total_orders,
    total_spent,
    benchmark_summary
FROM
    final_benchmark
WHERE
    available_quantity > 50 AND total_spent > 500
ORDER BY
    total_spent DESC, supplier_name;
