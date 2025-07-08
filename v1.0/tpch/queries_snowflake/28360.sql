WITH StringMetrics AS (
    SELECT
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        UPPER(p.p_name) AS name_upper,
        LOWER(p.p_name) AS name_lower,
        REPLACE(p.p_comment, ' ', '_') AS comment_replaced,
        CONCAT('Part: ', p.p_name, ', MFGR: ', p.p_mfgr) AS detailed_description
    FROM
        part p
),
SupplierNation AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_comment
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
),
SalesReport AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
)
SELECT
    sm.p_partkey,
    sm.name_length,
    sm.name_upper,
    sm.name_lower,
    sm.comment_replaced,
    sm.detailed_description,
    sn.s_name,
    sn.nation_name,
    sr.total_sales,
    CONCAT('Sales Report for Order: ', sr.o_orderkey, ' on ', sr.o_orderdate) AS sales_report
FROM
    StringMetrics sm
JOIN
    SupplierNation sn ON sn.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = sm.p_partkey LIMIT 1)
LEFT JOIN
    SalesReport sr ON sr.o_orderkey = (SELECT o.o_orderkey FROM orders o ORDER BY o.o_orderkey DESC LIMIT 1)
ORDER BY
    sm.name_length DESC, sr.total_sales DESC;
