WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name
    FROM
        SupplierSummary s
    WHERE
        s.total_value > (SELECT AVG(total_value) FROM SupplierSummary)
    ORDER BY
        s.total_value DESC
    LIMIT 5
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
)
SELECT
    c.c_name AS customer_name,
    o.o_orderkey AS order_id,
    o.o_orderdate AS order_date,
    o.o_totalprice AS total_price,
    s.s_name AS supplier_name,
    s.total_value AS supplier_total_value,
    s.part_count AS part_count
FROM
    CustomerOrders o
JOIN
    part p ON EXISTS (
        SELECT 1
        FROM lineitem l
        JOIN TopSuppliers s ON l.l_suppkey = s.s_suppkey
        WHERE l.l_orderkey = o.o_orderkey AND l.l_partkey = p.p_partkey
    )
JOIN
    TopSuppliers s ON EXISTS (
        SELECT 1
        FROM lineitem l
        WHERE l.l_orderkey = o.o_orderkey AND l.l_suppkey = s.s_suppkey
    )
ORDER BY
    o.o_totalprice DESC, s.s_name;
