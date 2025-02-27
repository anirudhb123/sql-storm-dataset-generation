WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        SUM(CASE WHEN ps.ps_supplycost > 1000 THEN ps.ps_availqty ELSE 0 END) OVER (PARTITION BY s.s_suppkey) AS high_value_supply,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE
        s.s_acctbal IS NOT NULL AND s.s_acctbal > (
            SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL
        )
    GROUP BY
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name
),
HighValueSuppliers AS (
    SELECT *
    FROM SupplierDetails
    WHERE high_value_supply > 100
),
OrdersInfo AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        AVG(l.l_discount) AS avg_discount,
        COUNT(l.l_orderkey) AS total_line_items,
        STRING_AGG(CASE WHEN l.l_returnflag = 'R' THEN 'Returned' ELSE 'Not Returned' END, ', ') AS return_status
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate > DATEADD(MONTH, -6, GETDATE())
    GROUP BY
        o.o_orderkey, o.o_totalprice
)
SELECT
    d.s_suppkey,
    d.s_name,
    d.part_count,
    o.o_orderkey,
    o.o_totalprice,
    o.avg_discount,
    o.total_line_items,
    o.return_status
FROM
    HighValueSuppliers d
FULL OUTER JOIN
    OrdersInfo o ON d.s_suppkey = (SELECT TOP 1 ps.ps_suppkey FROM partsupp ps WHERE ps.ps_availqty > 0 ORDER BY NEWID())
WHERE
    o.o_orderkey IS NULL OR d.s_suppkey IS NULL
ORDER BY
    COALESCE(d.s_name, 'Unknown Supplier'), o.o_totalprice DESC
