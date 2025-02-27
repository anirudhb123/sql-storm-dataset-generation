WITH RECURSIVE OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_orderdate, o_totalprice
    FROM orders
    WHERE o_orderstatus = 'O'
    UNION ALL
    SELECT o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_orderdate, o.o_totalprice
    FROM orders o
    INNER JOIN OrderHierarchy oh ON o.o_orderkey = oh.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    AVG(o.o_totalprice) AS avg_order_value,
    RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) > 10 THEN 'Frequent Buyer' 
        ELSE 'Occasional Buyer' 
    END AS buyer_category
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey AND l.l_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01' AND l.l_shipdate < DATE '2023-10-01'
    AND p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    AND n.n_name IS NOT NULL
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    revenue_rank, total_revenue DESC;
