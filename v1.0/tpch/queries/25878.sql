WITH RecursivePartInfo AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS mfgr_brand_info
    FROM
        part p
    WHERE
        p.p_size > 10
    UNION ALL
    SELECT
        ps.ps_partkey,
        'Associated Supplier' AS p_name,
        s.s_name AS p_mfgr,
        s.s_phone AS p_brand,
        'SUPPLIER' AS p_type,
        NULL AS p_size,
        NULL AS p_container,
        SUM(ps.ps_supplycost) AS p_retailprice,
        NULL AS p_comment,
        CONCAT('Supplier: ', s.s_name) AS mfgr_brand_info
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_name, s.s_phone
)
SELECT
    r.r_name,
    n.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    STRING_AGG(DISTINCT mpi.mfgr_brand_info, '; ') AS manufacturer_info
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    customer c ON o.o_custkey = c.c_custkey
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    RecursivePartInfo mpi ON l.l_partkey = mpi.p_partkey
WHERE
    l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    r.r_name, n.n_name
ORDER BY
    total_revenue DESC;