WITH SupplierStatistics AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrderStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT
        *
    FROM
        SupplierStatistics
    WHERE
        rank <= 10
),
TopCustomers AS (
    SELECT
        *
    FROM
        CustomerOrderStats
    WHERE
        total_orders > 5
)
SELECT
    c.c_custkey,
    c.c_name,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent_on_linenitems,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost_of_top_supplier,
    c.avg_order_value
FROM
    TopCustomers c
LEFT JOIN
    lineitem l ON EXISTS (
        SELECT 1
        FROM orders o
        WHERE o.o_custkey = c.c_custkey AND o.o_orderkey = l.l_orderkey
    )
LEFT JOIN
    TopSuppliers s ON s.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_brand = 'Brand#29'  -- Example for filtering parts by brand
    )
GROUP BY
    c.c_custkey, c.c_name, c.avg_order_value
ORDER BY
    total_spent_on_linenitems DESC
LIMIT 20;
