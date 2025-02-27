WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    WHERE
        s.s_acctbal IS NOT NULL
), 
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus = 'F'
    GROUP BY
        o.o_orderkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(total_revenue) FROM (
                SELECT 
                    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
                FROM 
                    orders o 
                JOIN 
                    lineitem l ON o.o_orderkey = l.l_orderkey
                GROUP BY 
                    o.o_orderkey
            ) AS avg_revenue
        )
), 
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        AVG(ps.ps_supplycost * (CASE 
            WHEN p.p_size IS NULL THEN 1 
            ELSE p.p_size END)) AS avg_supplycost
    FROM
        partsupp ps
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
), 
OuterJoinResult AS (
    SELECT
        h.o_orderkey,
        s.s_name,
        sp.avg_supplycost
    FROM
        HighValueOrders h
    LEFT JOIN
        RankedSuppliers s ON h.o_orderkey % 10 = s.s_suppkey % 10
    FULL OUTER JOIN
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
)
SELECT 
    o_orderkey,
    s_name,
    COALESCE(avg_supplycost, 0) AS avg_supplycost,
    CASE WHEN avg_supplycost IS NULL THEN 'No Supply' ELSE 'Supplied' END AS supply_status
FROM 
    OuterJoinResult
WHERE 
    o_orderkey IS NOT NULL
    AND (avg_supplycost IS NULL OR avg_supplycost > 100)
ORDER BY 
    o_orderkey DESC, s_name ASC;
