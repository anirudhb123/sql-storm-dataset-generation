
WITH SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM
        supplier s
    WHERE
        s.s_acctbal > (
            SELECT AVG(s2.s_acctbal)
            FROM supplier s2
            WHERE s2.s_nationkey = s.s_nationkey
        )
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        COUNT(l.l_orderkey) AS line_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1996-01-01' 
        AND o.o_orderstatus = 'O'
    GROUP BY
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > (
            SELECT AVG(l2.l_extendedprice)
            FROM lineitem l2
            WHERE l2.l_returnflag = 'N'
        )
),
RankedSuppliers AS (
    SELECT
        sd.s_suppkey,
        sd.s_name,
        r.r_name,
        sd.rn
    FROM
        SupplierDetails sd
    JOIN nation n ON sd.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    hvo.o_orderkey,
    hvo.o_totalprice,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    hvo.line_items,
    hvo.total_value,
    additional_info.additional_lines
FROM
    HighValueOrders hvo
LEFT JOIN
    lineitem l ON hvo.o_orderkey = l.l_orderkey
LEFT JOIN
    RankedSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN (
    SELECT
        l2.l_orderkey,
        COUNT(l2.l_linenumber) AS additional_lines
    FROM
        lineitem l2
    WHERE
        l2.l_returnflag = 'R'
    GROUP BY
        l2.l_orderkey
) AS additional_info ON additional_info.l_orderkey = hvo.o_orderkey
LEFT JOIN
    region r ON r.r_regionkey = (
        SELECT n.n_regionkey
        FROM nation n
        JOIN supplier s2 ON n.n_nationkey = s2.s_nationkey
        WHERE s2.s_suppkey = l.l_suppkey
        LIMIT 1
    )
WHERE
    hvo.total_value IS NOT NULL
    AND (s.rn IS NULL OR s.rn <= 5)
ORDER BY
    hvo.o_orderkey DESC, hvo.total_value DESC;
