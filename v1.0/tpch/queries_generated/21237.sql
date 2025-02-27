WITH RECURSIVE CTE_SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN CTE_SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
), 
CTE_AvgPrice AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank,
    CASE 
        WHEN COUNT(DISTINCT c.c_custkey) > 0 THEN 'Customer Exists'
        ELSE 'No Customers'
    END AS customer_status,
    COALESCE(NULLIF(AVG(CASE WHEN c.c_mktsegment = 'BUILDING' THEN c.c_acctbal ELSE NULL END), 0), 0) AS avg_account_building
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
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    CTE_SupplierHierarchy h ON s.s_suppkey = h.s_suppkey
WHERE 
    l.l_returnflag = 'N'
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    n.n_name, r.r_name, p.p_name
HAVING 
    total_revenue > (
        SELECT COALESCE(MAX(avg_supplycost), 0) 
        FROM CTE_AvgPrice 
        WHERE ps_partkey = p.p_partkey
    )
ORDER BY 
    nation_name, revenue_rank;

