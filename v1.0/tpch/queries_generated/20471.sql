WITH RECURSIVE OrderHierarchy AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        1 AS level
    FROM 
        orders o
    WHERE 
        o.o_orderstatus IN ('O', 'P') AND
        o.o_totalprice > (SELECT AVG(o_totalprice) FROM orders) 

    UNION ALL

    SELECT 
        o.o_orderkey, 
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        o.o_orderpriority,
        oh.level + 1
    FROM 
        orders o
    JOIN 
        OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey + 1
    WHERE 
        oh.level < 5
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty,
    COALESCE(NULLIF(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity END), 0), 0) AS total_returned,
    SUM(CASE WHEN l.l_linestatus = 'O' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_sales,
    AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_acctbal END) AS avg_building_cust_bal
FROM 
    part p
LEFT OUTER JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT OUTER JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
JOIN customer c ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = c.c_custkey)
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size < 30)
GROUP BY 
    p.p_partkey, 
    p.p_name, 
    ps.ps_availqty
HAVING 
    SUM(l.l_quantity) OVER (PARTITION BY p.p_partkey) IS NOT NULL
ORDER BY 
    total_sales DESC, 
    total_returned ASC
FETCH FIRST 10 ROWS ONLY
UNION
SELECT 
    DISTINCT n.n_nationkey AS p_partkey,
    n.n_name AS p_name,
    COUNT(s.s_suppkey) AS ps_availqty,
    COUNT(DISTINCT s.s_suppkey) AS total_returned,
    SUM(s.s_acctbal) AS total_sales,
    NULL AS avg_building_cust_bal
FROM 
    nation n
INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
WHERE 
    s.s_acctbal IS NOT NULL
GROUP BY 
    n.n_nationkey, 
    n.n_name
HAVING 
    COUNT(s.s_suppkey) > 0
ORDER BY 
    total_sales DESC
LIMIT 5;
