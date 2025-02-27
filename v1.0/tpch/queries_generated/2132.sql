WITH CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey, c.c_name
    ORDER BY
        total_spent DESC
    LIMIT 10
),
PartSuppliers AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey
),
SupplierRegions AS (
    SELECT
        s.s_suppkey,
        n.n_name AS nation_name,
        r.r_name AS region_name
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    tc.c_name,
    tc.total_spent,
    ps.ps_partkey,
    ps.total_supplycost,
    sr.nation_name,
    sr.region_name
FROM
    TopCustomers tc
LEFT JOIN
    PartSuppliers ps ON ps.ps_partkey IN (SELECT DISTINCT ps_partkey FROM partsupp WHERE ps_partkey IN (SELECT l.l_partkey FROM lineitem l JOIN orders o ON l.l_orderkey = o.o_orderkey WHERE o.o_custkey = tc.c_custkey))
LEFT JOIN
    SupplierRegions sr ON sr.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = ps.ps_partkey)
WHERE
    tc.total_spent > (SELECT AVG(total_spent) FROM TopCustomers)
ORDER BY
    tc.total_spent DESC, ps.total_supplycost DESC;
