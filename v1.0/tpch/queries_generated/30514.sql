WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
), RecentOrders AS (
    SELECT o_orderkey, o_custkey, o_totalprice, o_orderdate, RANK() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderdate >= DATEADD(DAY, -30, CURRENT_DATE)
), LineItemStats AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price
    FROM lineitem
    WHERE l_shipdate >= DATEADD(MONTH, -1, CURRENT_DATE) AND l_returnflag = 'N'
    GROUP BY l_orderkey
)
SELECT 
    p.p_name AS part_name, 
    p.p_brand AS brand, 
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    AVG(NULLIF(l.l_extendedprice, 0)) AS avg_price,
    MAX(NULLIF(sc.s_acctbal, 0)) AS max_supplier_balance,
    rh.r_name AS region_name
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    supplier sc ON ps.ps_suppkey = sc.s_suppkey
LEFT JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
LEFT JOIN 
    RecentOrders ro ON l.l_orderkey = ro.o_orderkey
LEFT JOIN 
    nation n ON sc.s_nationkey = n.n_nationkey
LEFT JOIN 
    region rh ON n.n_regionkey = rh.r_regionkey
JOIN 
    SupplierHierarchy sh ON sc.s_suppkey = sh.s_suppkey
WHERE 
    (p.p_size >= 10 AND p.p_size <= 20)
    OR (p.p_size IS NULL AND sh.level > 1)
GROUP BY 
    p.p_name, p.p_brand, rh.r_name
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 2
ORDER BY 
    total_quantity DESC, avg_price ASC;
