WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_shippriority,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as price_rank
    FROM
        orders o
),
FilteredSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal > (
            SELECT AVG(s_acctbal)
            FROM supplier
            WHERE s_comment IS NULL OR s_comment LIKE '%excellent%'
        )
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerRegion AS (
    SELECT
        c.c_custkey,
        c.c_name,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(o.o_totalprice) DESC) AS region_rank
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, n.n_name, r.r_name
)
SELECT
    p.p_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    AVG(NULLIF(ps.ps_supplycost, 0)) AS avg_supply_cost,
    STRING_AGG(DISTINCT r.region_name, '; ') AS regions_supplied,
    CASE 
        WHEN SUM(l.l_quantity) > 100 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM
    part p
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    RankedOrders ro ON l.l_orderkey = ro.o_orderkey
JOIN
    FilteredSuppliers fs ON fs.s_suppkey = l.l_suppkey
JOIN
    CustomerRegion cr ON cr.c_custkey = ro.o_orderkey % (SELECT COUNT(*) FROM customer)
GROUP BY
    p.p_name
HAVING
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (
        SELECT AVG(total_revenue) 
        FROM (
            SELECT SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
            FROM lineitem
            GROUP BY l_orderkey
        ) AS subquery
    )
ORDER BY
    revenue DESC NULLS LAST;
