WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        0 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '2023-01-01'
    
    UNION ALL

    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        o.o_clerk,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_custkey = oh.o_orderkey
)
SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_price,
    nt.n_name AS nation_name,
    CASE 
        WHEN s.s_acctbal IS NULL THEN 'Unknown Balance'
        ELSE CAST(s.s_acctbal AS varchar)
    END AS supplier_balance,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    customer c ON l.l_orderkey = c.c_custkey
LEFT JOIN 
    nation nt ON s.s_nationkey = nt.n_nationkey
LEFT JOIN 
    region r ON nt.n_regionkey = r.r_regionkey
JOIN 
    OrderHierarchy oh ON l.l_orderkey = oh.o_orderkey
WHERE 
    l.l_returnflag = 'N'
    AND l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (p.p_size IS NOT NULL OR p.p_container IS NOT NULL)
GROUP BY 
    p.p_name, nt.n_name, s.s_acctbal
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue DESC;
