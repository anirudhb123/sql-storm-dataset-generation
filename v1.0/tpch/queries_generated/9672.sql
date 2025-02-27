WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS rnk
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rnk
    FROM
        customer c
    WHERE
        c.c_acctbal > 10000
),
Summary AS (
    SELECT
        n.n_name AS nation,
        r.r_name AS region,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        n.n_name, r.r_name
)
SELECT
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_account_balance,
    hv.c_name AS high_value_customer,
    hv.c_acctbal AS high_value_customer_balance,
    sum.total_orders,
    sum.total_revenue
FROM
    RankedSuppliers s
JOIN
    HighValueCustomers hv ON s.rnk = 1
JOIN
    Summary sum ON sum.nation = (SELECT n_name FROM nation WHERE n_nationkey = (SELECT c_nationkey FROM customer WHERE c_custkey = hv.c_custkey))
WHERE
    s.s_acctbal >= 50000
ORDER BY
    sum.total_revenue DESC, s.s_acctbal DESC;
