
WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        0 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 5000

    UNION ALL

    SELECT 
        ps.ps_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        sh.level + 1
    FROM 
        partsupp ps
    JOIN 
        SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE 
        s.s_acctbal > 3000
), 
CustomerOrderCounts AS (
    SELECT 
        c.c_custkey, 
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
)

SELECT 
    p.p_name, 
    p.p_brand, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    COUNT(DISTINCT CASE WHEN l.l_returnflag = 'R' THEN l.l_orderkey END) AS refund_count,
    ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region'
        ELSE r.r_name 
    END AS region_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY 
    p.p_name, p.p_brand, r.r_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > (SELECT AVG(order_count) FROM CustomerOrderCounts)
ORDER BY 
    total_revenue DESC
LIMIT 10;
