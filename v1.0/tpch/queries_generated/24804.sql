WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_custkey,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice) FROM orders o2 WHERE o2.o_orderstatus = 'F'
        )
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS total_supplied_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
TopCustomers AS (
    SELECT
        cs.c_custkey,
        cs.total_orders,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        CustomerStats cs
    WHERE
        cs.total_orders > (SELECT AVG(total_orders) FROM CustomerStats)
),
FilteredSuppliers AS (
    SELECT
        ss.s_suppkey,
        ss.total_supplied_parts,
        ss.total_supply_value
    FROM
        SupplierStats ss
    WHERE
        ss.total_supply_value > (
            SELECT AVG(total_supply_value) FROM SupplierStats
        )
)
SELECT
    t.c_custkey,
    t.total_orders,
    t.total_spent,
    COALESCE(fs.total_supplied_parts, 0) AS total_supplied_parts,
    COALESCE(fs.total_supply_value, 0) AS total_supply_value
FROM
    TopCustomers t
LEFT JOIN
    FilteredSuppliers fs ON EXISTS (
        SELECT 1 FROM lineitem l
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = t.c_custkey)
        AND l.l_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
    )
UNION ALL
SELECT
    NULL AS c_custkey,
    NULL AS total_orders,
    NULL AS total_spent,
    SUM(ss.total_supplied_parts) AS total_supplied_parts,
    SUM(ss.total_supply_value) AS total_supply_value
FROM
    FilteredSuppliers ss
WHERE
    ss.total_supplying_parts > 1000
ORDER BY
    t.total_spent DESC NULLS LAST, fs.total_supply_value DESC NULLS LAST;
