WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, o.o_orderkey
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(co.total_spent) AS total_spent
    FROM
        CustomerOrders co
    JOIN
        customer c ON co.c_custkey = c.c_custkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(co.total_spent) > 10000
)
SELECT
    nc.n_name AS nation_name,
    rc.r_name AS region_name,
    COUNT(DISTINCT tc.c_custkey) AS top_customer_count,
    SUM(ps.ps_supplycost) AS total_supply_cost
FROM
    nation nc
JOIN
    region rc ON nc.n_regionkey = rc.r_regionkey
LEFT JOIN
    RankedSuppliers rs ON rs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size >= 20))
LEFT JOIN
    TopCustomers tc ON nc.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = tc.c_custkey)
GROUP BY
    nc.n_name, rc.r_name
ORDER BY
    total_supply_cost DESC;
