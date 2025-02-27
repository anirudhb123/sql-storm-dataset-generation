WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
),
CustomerOrderSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COALESCE(SUM(lo.l_extendedprice * (1 - lo.l_discount)), 0) AS total_spent,
        COUNT(lo.l_orderkey) AS order_count
    FROM
        customer c
    LEFT JOIN
        lineitem lo ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = lo.l_orderkey)
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    r.r_name AS region,
    n.n_name AS nation,
    cs.c_name AS customer_name,
    cs.total_spent,
    o.o_orderkey,
    o.o_orderdate,
    CASE
        WHEN o.o_orderstatus = 'O' THEN 'Open Order'
        WHEN o.o_orderstatus = 'F' THEN 'Finished Order'
        ELSE 'Unknown Status'
    END AS order_status,
    fs.total_supply_cost
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    customer c ON n.n_nationkey = c.c_nationkey
JOIN
    CustomerOrderSummary cs ON cs.c_custkey = c.c_custkey
LEFT JOIN
    RankedOrders o ON cs.c_custkey = (SELECT o2.o_custkey FROM orders o2 WHERE o2.o_orderkey = o.o_orderkey)
LEFT JOIN
    FilteredSuppliers fs ON fs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = o.o_orderkey LIMIT 1))
WHERE
    cs.total_spent > 5000 AND
    (fs.total_supply_cost IS NULL OR fs.total_supply_cost > 150000)
ORDER BY
    region, nation, customer_name;
