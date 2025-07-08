
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
CustomerOrders AS (
    SELECT
        o.o_orderkey,
        c.c_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, c.c_custkey
),
NationRegion AS (
    SELECT
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        nation n
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
    GROUP BY
        n.n_name, r.r_name
)
SELECT
    co.c_custkey,
    SUM(co.total_revenue) AS total_order_revenue,
    AVG(nr.total_supply_cost) AS average_supply_cost,
    LISTAGG(DISTINCT rs.s_name, ', ') WITHIN GROUP (ORDER BY rs.s_name) AS supplier_names
FROM
    CustomerOrders co
LEFT JOIN
    RankedSuppliers rs ON co.o_orderkey = rs.s_suppkey
LEFT JOIN
    NationRegion nr ON nr.nation_name IN (SELECT n.n_name FROM nation n WHERE n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey))
GROUP BY
    co.c_custkey
HAVING
    SUM(co.total_revenue) > (SELECT AVG(total_revenue) FROM CustomerOrders)
ORDER BY
    total_order_revenue DESC;
