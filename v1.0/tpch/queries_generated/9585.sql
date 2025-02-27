WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_nationkey
),

CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O' AND o.o_orderdate >= '2023-01-01'
    GROUP BY
        c.c_custkey, c.c_name
)

SELECT
    r.region_name,
    cs.cust_name,
    cs.total_spent,
    rs.s_name AS top_supplier,
    rs.total_supply_cost
FROM
    (SELECT
         r.r_name AS region_name,
         n.n_nationkey
     FROM
         region r
     JOIN
         nation n ON r.r_regionkey = n.n_regionkey) r
JOIN
    CustomerOrders cs ON cs.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = r.n_nationkey)
JOIN
    RankedSuppliers rs ON rs.rank = 1
ORDER BY
    cs.total_spent DESC, rs.total_supply_cost DESC
LIMIT 100;
