WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_name
),
TopRegions AS (
    SELECT
        nation_name
    FROM
        RegionalSales
    WHERE
        sales_rank <= 3
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_price,
        COUNT(l.l_orderkey) AS item_count,
        n.n_name AS nation_name
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate BETWEEN DATE '2023-01-01' AND DATE '2023-12-31'
    GROUP BY
        o.o_orderkey, n.n_name
),
FinalReport AS (
    SELECT
        od.o_orderkey,
        od.total_order_price,
        od.item_count,
        od.nation_name,
        CASE
            WHEN od.total_order_price > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS order_value_category
    FROM
        OrderDetails od
    WHERE
        od.nation_name IN (SELECT nation_name FROM TopRegions)
)
SELECT
    fr.order_value_category,
    COUNT(*) AS num_orders,
    AVG(fr.total_order_price) AS avg_order_value,
    SUM(fr.item_count) AS total_items
FROM
    FinalReport fr
GROUP BY
    fr.order_value_category
HAVING
    SUM(fr.total_order_price) IS NOT NULL
ORDER BY
    order_value_category ASC
LIMIT 5 OFFSET 0;

WITH RECURSIVE SalesHierarchy AS (
    SELECT
        n.n_name,
        n.n_nationkey,
        COUNT(*) AS level
    FROM
        nation n
    GROUP BY
        n.n_name, n.n_nationkey
    UNION ALL
    SELECT
        n.n_name,
        s.s_nationkey AS n_nationkey,
        sh.level + 1
    FROM
        SalesHierarchy sh
    JOIN
        supplier s ON s.s_nationkey = (
            SELECT n.n_nationkey
            FROM nation n
            WHERE n.n_name = sh.n_name
        )
    WHERE
        sh.level < 3
)
SELECT
    n.n_name,
    COUNT(s.s_suppkey) AS supplier_count
FROM
    nation n
LEFT OUTER JOIN supplier s ON n.n_nationkey = s.s_nationkey
GROUP BY
    n.n_name
HAVING
    COUNT(s.s_suppkey) > (SELECT COUNT(*) FROM supplier WHERE s_acctbal IS NULL)
ORDER BY
    supplier_count DESC, n.n_name ASC
LIMIT 10 OFFSET 0;
