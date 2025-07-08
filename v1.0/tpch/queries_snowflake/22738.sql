
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS effective_comment,
        CASE
            WHEN p.p_retailprice > 100 THEN 'High-End'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Mid-Range'
            ELSE 'Budget'
        END AS price_category
    FROM
        part p
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_availability,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
OrderDetails AS (
    SELECT
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_sales,
        COUNT(DISTINCT lo.l_partkey) AS line_item_count,
        AVG(lo.l_quantity) AS avg_quantity_per_line
    FROM
        lineitem lo
    GROUP BY
        lo.l_orderkey
)
SELECT
    fo.p_partkey,
    fo.p_name,
    fo.effective_comment,
    fo.price_category,
    ss.unique_parts,
    ss.total_availability,
    ss.avg_supply_cost,
    od.total_sales,
    od.line_item_count,
    od.avg_quantity_per_line,
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice
FROM
    FilteredParts fo
LEFT JOIN
    SupplierStats ss ON fo.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey IN (SELECT s.s_suppkey FROM supplier s))
LEFT JOIN
    OrderDetails od ON od.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F')
RIGHT JOIN
    RankedOrders ro ON ro.o_orderkey = od.l_orderkey
WHERE
    fo.price_category = 'High-End'
    AND ss.total_availability > 100
ORDER BY
    ro.o_totalprice DESC, fo.p_name ASC
LIMIT 50;
