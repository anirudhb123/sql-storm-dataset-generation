WITH SupplierSummary AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey
)
SELECT
    n.n_name,
    r.r_name,
    s.s_name,
    COALESCE(ss.total_supply_cost, 0) AS supplier_cost,
    COALESCE(co.total_orders, 0) AS customer_orders,
    COALESCE(co.total_spent, 0) AS customer_spent,
    COUNT(DISTINCT p.p_partkey) AS part_count,
    AVG(p.p_retailprice) AS avg_part_price,
    MAX(p.p_size) AS max_part_size
FROM
    nation n
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    SupplierSummary ss ON s.s_suppkey = ss.s_suppkey
LEFT JOIN
    CustomerOrders co ON n.n_nationkey = (SELECT c.c_nationkey FROM customer c WHERE c.c_custkey = co.c_custkey)
LEFT JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY
    n.n_name, r.r_name, s.s_name
HAVING
    AVG(p.p_retailprice) > (SELECT AVG(p_retailprice) FROM part) AND
    COUNT(DISTINCT ps.ps_partkey) > 10
ORDER BY
    supplier_cost DESC, customer_orders ASC;
