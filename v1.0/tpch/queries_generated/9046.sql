WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(ss.total_cost) AS total_supplier_cost,
    SUM(co.total_spent) AS total_customer_spending,
    COUNT(DISTINCT ss.s_suppkey) AS distinct_suppliers,
    COUNT(DISTINCT co.c_custkey) AS distinct_customers
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    SupplierStats ss ON n.n_nationkey = (SELECT s.n_nationkey FROM supplier s WHERE s.s_suppkey = ss.s_suppkey)
LEFT JOIN
    CustomerOrders co ON n.n_nationkey = c.c_nationkey
GROUP BY
    n.n_name, r.r_name
ORDER BY
    total_supplier_cost DESC, total_customer_spending DESC;
