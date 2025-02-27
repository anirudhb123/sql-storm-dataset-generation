WITH RECURSIVE Quantities AS (
    SELECT
        ps_partkey,
        SUM(ps_availqty) AS total_quantity,
        COUNT(ps_suppkey) AS supplier_count
    FROM
        partsupp
    GROUP BY
        ps_partkey
),
QualifiedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        CASE
            WHEN s.s_acctbal IS NULL THEN 'N/A'
            ELSE FORMAT(s.s_acctbal, 'C', 'en-US')
        END AS formatted_acct_bal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank_bal
    FROM
        supplier s
    WHERE
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
ProductsWithFlags AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        CASE
            WHEN (p.p_retailprice < 10.00) THEN 'Cheap'
            WHEN (p.p_retailprice BETWEEN 10.00 AND 100.00) THEN 'Moderate'
            ELSE 'Expensive'
        END AS price_category
    FROM
        part p
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_lineitem) AS total_items,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY
        o.o_orderkey
)
SELECT
    p.p_partkey,
    p.p_name,
    q.total_quantity,
    qs.s_name AS qualified_supplier_name,
    qs.formatted_acct_bal,
    od.total_items,
    od.total_value,
    CASE
        WHEN q.supplier_count = 0 THEN 'No suppliers available'
        ELSE CAST(q.supplier_count AS VARCHAR)
    END AS supplier_count_report,
    p.price_category
FROM
    ProductsWithFlags p
LEFT JOIN
    Quantities q ON p.p_partkey = q.ps_partkey
LEFT JOIN
    QualifiedSuppliers qs ON q.ps_partkey = (SELECT ps_partkey FROM partsupp WHERE ps_availqty = (SELECT MAX(ps_availqty) FROM partsupp WHERE ps_partkey = q.ps_partkey))
LEFT JOIN
    OrderDetails od ON od.o_orderkey = (SELECT TOP 1 o_orderkey FROM orders ORDER BY o_orderdate DESC)
WHERE
    (p.p_retailprice IS NOT NULL AND p.p_retailprice > 0)
    AND (p.p_comment NOT LIKE '%defective%')
ORDER BY
    od.total_value DESC NULLS LAST,
    p.p_name ASC;
