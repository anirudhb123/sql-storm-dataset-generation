WITH RECURSIVE SalesCTE AS (
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
    HAVING
        total_sales > 1000
    
    UNION ALL
    
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) + s.total_sales
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        SalesCTE s ON s.o_orderkey = o.o_orderkey
    WHERE
        s.total_sales IS NOT NULL
)

SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(SCTE.total_sales), 0) AS total_sales,
    s.s_name AS supplier_name,
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
    (SELECT DISTINCT o.o_orderkey, o.o_orderdate 
     FROM orders o 
     WHERE o.o_orderstatus = 'F') O ON O.o_orderkey IN (SELECT o.o_orderkey FROM orders o)
LEFT JOIN
    SalesCTE SCTE ON SCTE.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = p.p_partkey)
GROUP BY
    p.p_partkey, p.p_name, s.s_name, r.r_name
ORDER BY
    total_sales DESC
LIMIT 10;
