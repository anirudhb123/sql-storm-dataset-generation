
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
),

SupplierParts AS (
    SELECT
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey
),

HighValueOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        CASE 
            WHEN ro.o_totalprice > 1000 THEN 'High'
            ELSE 'Regular'
        END AS order_type
    FROM
        RankedOrders ro
    WHERE
        ro.order_rank <= 10
),

FinalJoin AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COALESCE(sp.total_available_qty, 0) AS available_qty,
        COALESCE(sp.avg_supply_cost, 0) AS avg_cost,
        hvo.order_type
    FROM
        part p
    LEFT JOIN
        SupplierParts sp ON p.p_partkey = sp.ps_partkey
    LEFT JOIN
        HighValueOrders hvo ON EXISTS (
            SELECT 1 
            FROM lineitem l 
            WHERE l.l_orderkey = hvo.o_orderkey
            AND l.l_partkey = p.p_partkey
        )
)

SELECT
    f.p_partkey,
    f.p_name,
    f.available_qty,
    f.avg_cost,
    f.order_type
FROM
    FinalJoin f
WHERE
    f.available_qty > 0
ORDER BY
    f.avg_cost DESC, f.available_qty ASC;
