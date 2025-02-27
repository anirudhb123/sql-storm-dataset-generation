WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SupplierParts AS (
    SELECT
        s.s_suppkey,
        COUNT(ps.ps_partkey) AS supply_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING
        SUM(o.o_totalprice) > 10000
)
SELECT
    p.p_partkey,
    p.p_name,
    ROUND(AVG(l.l_extendedprice * (1 - l.l_discount)), 2) AS avg_price,
    COALESCE(sp.supply_count, 0) AS supply_count,
    COALESCE(hc.total_spent, 0) AS total_spent
FROM
    part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN SupplierParts sp ON sp.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    WHERE ps.ps_partkey = p.p_partkey
    ORDER BY ps.ps_supplycost DESC
    LIMIT 1
)
LEFT JOIN HighValueCustomers hc ON hc.c_custkey = (
    SELECT o.o_custkey
    FROM orders o
    WHERE o.o_orderkey = (
        SELECT o_orderkey FROM RankedOrders r
        WHERE r.order_rank = 1 AND r.o_orderstatus = 'F'
        LIMIT 1
    )
)
WHERE
    p.p_retailprice IS NOT NULL
GROUP BY
    p.p_partkey, p.p_name, sp.supply_count, hc.total_spent
HAVING
    AVG(l.l_extendedprice * (1 - l.l_discount)) > 500
ORDER BY
    avg_price DESC, supply_count DESC;