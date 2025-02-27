WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as rank
    FROM
        supplier s
    INNER JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > 1000.00
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.order_count,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS customer_rank
    FROM
        CustomerOrders c
    WHERE
        c.total_spent > 5000.00
)
SELECT
    pc.p_partkey,
    pc.p_name,
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    AVG(COALESCE(l.l_extendedprice, 0)) AS avg_price,
    ts.c_name AS top_customer,
    MAX(rs.s_name) AS top_supplier
FROM
    part pc
LEFT JOIN
    lineitem l ON pc.p_partkey = l.l_partkey
LEFT JOIN
    RankedSuppliers rs ON l.l_suppkey = rs.s_suppkey AND rs.rank = 1
LEFT JOIN
    TopCustomers ts ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = ts.c_custkey)
GROUP BY
    pc.p_partkey, pc.p_name, ts.c_name
HAVING
    SUM(l.l_quantity) IS NOT NULL AND AVG(l.l_extendedprice) > 100
ORDER BY
    total_quantity DESC, avg_price ASC;
