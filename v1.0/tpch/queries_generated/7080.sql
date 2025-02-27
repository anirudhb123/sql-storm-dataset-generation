WITH SupplierAggregate AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate > '2023-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
CustomerOrderCount AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
)
SELECT
    r.r_name,
    SUM(SA.total_available_quantity) AS total_available_quantity,
    COUNT(DISTINCT CO.c_custkey) AS unique_customers,
    AVG(OD.total_order_value) AS average_order_value,
    CO.order_count
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    SupplierAggregate SA ON s.s_suppkey = SA.s_suppkey
JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    OrderDetails OD ON c.c_custkey IN (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = OD.o_orderkey)
LEFT JOIN
    CustomerOrderCount CO ON c.c_custkey = CO.c_custkey
GROUP BY
    r.r_name, CO.order_count
HAVING
    SUM(SA.total_available_quantity) > 1000 AND AVG(OD.total_order_value) > 500
ORDER BY
    r.r_name;
