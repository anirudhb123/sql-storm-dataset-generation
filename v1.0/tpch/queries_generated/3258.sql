WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        c.c_name,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '2023-01-01'
        AND o.o_orderdate < DATE '2023-12-31'
),
SupplierCosts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),
PartDetails AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(s.total_supply_cost, 0) AS total_supply_cost
    FROM
        part p
    LEFT JOIN
        SupplierCosts s ON p.p_partkey = s.ps_partkey
)
SELECT
    r.r_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(p.total_supply_cost) AS total_cost_of_parts,
    AVG(o.o_totalprice) AS average_order_value,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM
    RankedOrders o
JOIN
    nation n ON o.c_custkey IN (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey)
JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    PartDetails p ON o.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey)
WHERE
    o.rn <= 10
GROUP BY
    r.r_name
HAVING
    total_orders > 5
ORDER BY
    total_cost_of_parts DESC;
