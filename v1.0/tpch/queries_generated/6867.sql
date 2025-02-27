WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        n.n_name IN (SELECT n_name FROM nation WHERE r_regionkey = 1)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS number_of_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.total_spent
    FROM
        CustomerOrders c
    WHERE
        c.total_spent > 10000
)
SELECT
    r.r_name,
    s.s_name,
    AVG(ls.l_extendedprice) AS avg_price,
    SUM(ls.l_quantity) AS total_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM
    lineitem ls
JOIN
    orders o ON ls.l_orderkey = o.o_orderkey
JOIN
    RankedSuppliers s ON ls.l_suppkey = s.s_suppkey
JOIN
    supplier sp ON s.s_suppkey = sp.s_suppkey
JOIN
    nation n ON sp.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    s.rn = 1
AND
    o.o_orderstatus = 'O'
AND
    EXISTS (
        SELECT 1
        FROM HighValueCustomers hvc
        WHERE hvc.c_custkey = o.o_custkey
    )
GROUP BY
    r.r_name, s.s_name
ORDER BY
    r.r_name, avg_price DESC;
