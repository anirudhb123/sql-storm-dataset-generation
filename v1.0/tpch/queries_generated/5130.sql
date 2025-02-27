WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '2023-01-01' AND o.o_orderdate < DATE '2024-01-01'
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderstatus = 'O'
    GROUP BY
        c.c_custkey
),
SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
TopRegions AS (
    SELECT 
        n.n_regionkey,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        l.l_shipdate >= DATE '2023-03-01' AND l.l_shipdate < DATE '2023-10-01'
    GROUP BY
        n.n_regionkey, r.r_name
    ORDER BY
        total_revenue DESC
    LIMIT 5
)
SELECT
    r.r_name,
    r.total_revenue,
    cs.total_spent,
    cs.order_count,
    sp.avg_supply_cost
FROM
    TopRegions r
JOIN
    CustomerStats cs ON cs.total_spent > 10000
JOIN
    SupplierPerformance sp ON sp.total_parts > 50
WHERE
    r.total_revenue > 50000
ORDER BY
    r.total_revenue DESC, cs.total_spent DESC;
