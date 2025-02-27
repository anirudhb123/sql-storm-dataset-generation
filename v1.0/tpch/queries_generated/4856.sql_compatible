
WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_sales
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        l.l_shipdate >= '1997-01-01'
        AND l.l_shipdate < '1998-01-01'
        AND o.o_orderstatus = 'O'
    GROUP BY
        n.n_name
),
TopRegions AS (
    SELECT
        nation_name,
        total_sales,
        order_count,
        rank_sales
    FROM
        RegionalSales
    WHERE
        rank_sales <= 5
)
SELECT
    tr.nation_name,
    tr.total_sales,
    tr.order_count,
    CASE
        WHEN tr.total_sales > 1000000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    COALESCE((
        SELECT AVG(s.s_acctbal)
        FROM supplier s
        JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_retailprice > 100
        AND p.p_container = 'BOX'
        AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name = tr.nation_name)
    ), 0) AS avg_supplier_balance
FROM
    TopRegions tr
LEFT JOIN
    region rg ON rg.r_regionkey IN (
        SELECT n.n_regionkey FROM nation n WHERE n.n_name = tr.nation_name
    )
ORDER BY
    tr.total_sales DESC;
