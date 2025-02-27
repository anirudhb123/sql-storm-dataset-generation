WITH supplier_part_details AS (
    SELECT
        s.s_name AS supplier_name,
        p.p_name AS part_name,
        ps.ps_supplycost AS supply_cost,
        ps.ps_availqty AS available_quantity,
        CONCAT(s.s_name, ' supplies ', p.p_name, ' at a cost of ', CAST(ps.ps_supplycost AS VARCHAR(12)), ' with availability of ', CAST(ps.ps_availqty AS VARCHAR(10))) AS description
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
),
customer_order_summary AS (
    SELECT
        c.c_name AS customer_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        STRING_AGG(CONCAT('Order ID: ', o.o_orderkey, ' of ', CAST(o.o_totalprice AS DECIMAL(12, 2)), ' on ', CAST(o.o_orderdate AS DATE)), '; ') AS order_details
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_name
)
SELECT
    spd.supplier_name,
    spd.part_name,
    spd.supply_cost,
    spd.available_quantity,
    spd.description,
    cos.customer_name,
    cos.total_orders,
    cos.total_spent,
    cos.order_details
FROM
    supplier_part_details spd
JOIN customer_order_summary cos ON spd.supplier_name LIKE '%' || cos.customer_name || '%'
WHERE
    spd.available_quantity > 100
ORDER BY
    spd.supply_cost DESC, cos.total_spent DESC;
