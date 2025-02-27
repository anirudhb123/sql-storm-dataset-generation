WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
)

SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS latest_ship_date,
    STRING_AGG(DISTINCT p.p_name, ', ') AS part_names,
    AVG(s.s_acctbal) AS avg_account_balance,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    l.l_shipdate >= DATE '2023-01-01'
    AND EXISTS (
        SELECT 1
        FROM SupplierHierarchy sh
        WHERE sh.s_suppkey = s.s_suppkey
    )
GROUP BY 
    n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 
    (SELECT AVG(total_revenue)
     FROM (
          SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
          FROM lineitem l2
          JOIN orders o2 ON l2.l_orderkey = o2.o_orderkey
          GROUP BY o2.o_orderkey) AS order_revenue)
ORDER BY 
    total_orders DESC, 
    latest_ship_date DESC;
