WITH OrderSummary AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count,
        AVG(l.l_quantity) AS avg_quantity,
        MAX(l.l_shipdate) AS latest_shipdate,
        MIN(l.l_shipdate) AS earliest_shipdate,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    LEFT JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        total_supplycost > (SELECT AVG(ps_supplycost) FROM partsupp)
),
TaxedOrders AS (
    SELECT
        os.o_orderkey,
        CASE
            WHEN SUM(l.l_tax) = 0 THEN NULL
            ELSE SUM(l.l_extendedprice) / SUM(l.l_tax)
        END AS tax_ratio
    FROM
        OrderSummary os
    JOIN
        lineitem l ON os.o_orderkey = l.l_orderkey
    WHERE
        os.total_price >= 1000
    GROUP BY
        os.o_orderkey
)
SELECT
    od.o_orderkey,
    sd.s_name,
    od.total_price,
    od.supplier_count,
    od.avg_quantity,
    COALESCE(td.tax_ratio, 0) AS tax_ratio,
    CASE
        WHEN od.latest_shipdate IS NOT NULL AND od.earliest_shipdate IS NOT NULL THEN 
            DATEDIFF(od.latest_shipdate, od.earliest_shipdate)
        ELSE NULL
    END AS shipping_duration
FROM
    OrderSummary od
LEFT JOIN
    SupplierDetails sd ON od.supplier_count = (SELECT COUNT(*) FROM SupplierDetails)
LEFT JOIN
    TaxedOrders td ON od.o_orderkey = td.o_orderkey
WHERE
    od.rn = 1
ORDER BY
    shipping_duration DESC NULLS LAST
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
