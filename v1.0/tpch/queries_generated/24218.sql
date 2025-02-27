WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1996-01-01' AND o.o_orderdate < '1997-01-01'
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
PartAmounts AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    GROUP BY
        l.l_partkey
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    p.p_partkey,
    p.p_name,
    ps.total_supply_cost,
    COALESCE(pa.total_revenue, 0) AS total_revenue,
    cs.order_count,
    cs.total_spent,
    r.r_name
FROM
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    PartAmounts pa ON p.p_partkey = pa.l_partkey
LEFT JOIN 
    CustomerStats cs ON cs.order_count > 0
LEFT JOIN 
    nation n ON cs.c_custkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    ps.ps_availqty > (
        SELECT AVG(ps_availqty)
        FROM partsupp
        WHERE ps_supplycost < 100
    )
    AND (r.r_name IS NOT NULL OR cs.total_spent IS NULL)
    OR EXISTS (
        SELECT 1
        FROM RankedOrders ro
        WHERE ro.o_orderkey = cs.order_count AND ro.order_rank = 1
    )
ORDER BY
    total_revenue DESC, total_spent DESC NULLS LAST;
