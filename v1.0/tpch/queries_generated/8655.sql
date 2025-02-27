WITH CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
SupplierPartDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
PopularItems AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_quantity) AS total_quantity_sold
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name
    HAVING
        SUM(l.l_quantity) > 100
)
SELECT
    co.c_name,
    co.total_orders,
    co.total_spent,
    sp.s_name AS supplier_name,
    sp.total_available_qty,
    sp.total_supply_cost,
    pi.p_name,
    pi.total_quantity_sold
FROM
    CustomerOrders co
JOIN
    SupplierPartDetails sp ON sp.total_available_qty > 0
JOIN
    PopularItems pi ON pi.total_quantity_sold > 100
ORDER BY
    co.total_spent DESC, pi.total_quantity_sold DESC
LIMIT 10;
