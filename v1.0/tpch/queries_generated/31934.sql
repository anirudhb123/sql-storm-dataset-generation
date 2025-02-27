WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000.00
    
    UNION ALL
    
    SELECT ps.ps_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_partkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 50
),
TopCustomers AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spend
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING SUM(o.o_totalprice) > 5000.00
),
RegionNation AS (
    SELECT r.r_name, n.n_name
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
)
SELECT 
    s.s_name AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_extended_price,
    STRING_AGG(DISTINCT CONCAT(rn.r_name, ' - ', rn.n_name), '; ') AS region_nation,
    ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY COUNT(o.o_orderkey) DESC) AS rank
FROM 
    supplier s
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    TopCustomers tc ON o.o_custkey = tc.c_custkey
JOIN 
    RegionNation rn ON s.s_nationkey = rn.n.n_nationkey
WHERE 
    l.l_returnflag = 'N' 
    AND l.l_discount BETWEEN 0.05 AND 0.15
    AND EXISTS (
        SELECT 1 
        FROM SupplierHierarchy sh 
        WHERE sh.s_suppkey = s.s_suppkey
    )
GROUP BY 
    s.s_name, s.s_nationkey
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    rank, total_orders DESC;
