
WITH RECURSIVE SalesCTE AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS sales_rank
    FROM
        orders o
    JOIN
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderdate

    UNION ALL

    SELECT
        s.o_orderkey,
        s.o_orderdate,
        s.total_sales + c.total_sales AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.o_orderkey ORDER BY s.o_orderdate DESC) AS sales_rank
    FROM
        SalesCTE s
    JOIN
        SalesCTE c ON s.o_orderkey = c.o_orderkey
    WHERE
        s.sales_rank = 1 AND c.sales_rank > 1
)
SELECT
    p.p_name,
    SUM(li.l_quantity) AS total_quantity,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
    AVG(li.l_tax) AS avg_tax,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    r.r_name AS region_name
FROM
    part p
LEFT JOIN
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN
    lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN
    orders o ON li.l_orderkey = o.o_orderkey
WHERE
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND (li.l_discount = 0 OR li.l_tax > 0)
GROUP BY
    p.p_name, r.r_name
HAVING
    SUM(li.l_quantity) > 100
ORDER BY
    total_revenue DESC
FETCH FIRST 10 ROWS ONLY;
