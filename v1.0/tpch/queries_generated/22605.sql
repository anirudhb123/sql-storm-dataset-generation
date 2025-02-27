WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL
    
    UNION ALL
    
    SELECT sp.s_suppkey, sp.s_name, sp.s_nationkey, sp.s_acctbal, sh.level + 1
    FROM supplier AS sp
    JOIN SupplierHierarchy AS sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 500000
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(o.o_orderkey) > 10
),
RankedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, RANK() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_extendedprice DESC) AS price_rank
    FROM lineitem l
    WHERE l.l_returnflag = 'N'
)
SELECT DISTINCT 
    p.p_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN r.r_name IS NULL THEN 'Unknown Region' 
        ELSE r.r_name 
    END AS region_name,
    sh.level AS supplier_level
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = s.s_nationkey)
JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    AND (l.l_discount >= 0.05 OR l.l_discount IS NULL)
    AND p.p_size BETWEEN 1 AND (SELECT MAX(p_size) FROM part p2 WHERE p2.p_brand = p.p_brand)
GROUP BY p.p_name, r.r_name, sh.level
HAVING revenue > (SELECT AVG(revenue) FROM (SELECT SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
                                            FROM lineitem l
                                            GROUP BY l.l_orderkey) AS sub)
ORDER BY revenue DESC, order_count DESC NULLS LAST;
