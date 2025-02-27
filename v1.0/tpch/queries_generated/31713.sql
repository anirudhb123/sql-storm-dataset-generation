WITH RECURSIVE FullOrderDetails AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        l.l_partkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_returnflag,
        l.l_linestatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderstatus IN ('F', 'P') 
    UNION ALL
    SELECT
        fod.o_orderkey,
        fod.o_orderdate,
        fod.o_totalprice,
        l2.l_partkey,
        l2.l_quantity,
        l2.l_extendedprice,
        l2.l_discount,
        l2.l_returnflag,
        l2.l_linestatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        FullOrderDetails fod
    JOIN
        lineitem l2 ON fod.o_orderkey = l2.l_orderkey
    JOIN
        orders o ON o.o_orderkey = fod.o_orderkey
    WHERE
        fod.order_rank < 5
)
SELECT 
    p.p_name,
    SUM(COALESCE(fod.l_quantity, 0)) AS total_quantity,
    SUM(fod.l_extendedprice * (1 - fod.l_discount)) AS total_revenue,
    COUNT(DISTINCT fod.o_orderkey) AS order_count,
    RANK() OVER (ORDER BY SUM(fod.l_extendedprice * (1 - fod.l_discount)) DESC) AS revenue_rank
FROM 
    FullOrderDetails fod
JOIN 
    part p ON fod.l_partkey = p.p_partkey
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE '%North%')
GROUP BY 
    p.p_name
HAVING 
    SUM(fod.l_extendedprice * (1 - fod.l_discount)) > 10000
ORDER BY 
    revenue_rank
LIMIT 10;
