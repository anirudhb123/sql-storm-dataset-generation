
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CTE1.total_qty,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rank
    FROM
        orders o
    JOIN (
        SELECT
            l.l_orderkey,
            SUM(l.l_quantity) AS total_qty
        FROM
            lineitem l
        GROUP BY
            l.l_orderkey
    ) AS CTE1 ON o.o_orderkey = CTE1.l_orderkey
    WHERE
        o.o_orderstatus = 'F'
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS part_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
HighValueSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        ss.total_supply_cost
    FROM
        supplier s
    JOIN SupplierStats ss ON s.s_suppkey = ss.s_suppkey
    WHERE
        ss.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    HVS.s_name AS supplier_name,
    HVS.total_supply_cost,
    COALESCE(total_value.total_value, 0) AS total_value
FROM
    RankedOrders ro
LEFT JOIN HighValueSuppliers HVS ON HVS.s_suppkey = (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_orderkey = ro.o_orderkey
    LIMIT 1
)
LEFT JOIN (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
) total_value ON total_value.l_orderkey = ro.o_orderkey
WHERE
    ro.rank = 1
ORDER BY
    ro.o_orderdate DESC, 
    total_value DESC;
