WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 5000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 3000 AND sh.level < 5
),
MarketSegments AS (
    SELECT c.c_mktsegment, COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE c.c_acctbal IS NOT NULL AND o.o_orderdate >= '1996-01-01'
    GROUP BY c.c_mktsegment
),
MaxRetailPrice AS (
    SELECT MAX(p.p_retailprice) AS max_price, p.p_type
    FROM part p
    GROUP BY p.p_type
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supply_cost,
    AVG(o.o_totalprice) AS avg_order_price,
    ms.order_count AS segment_order_count,
    CONCAT('Highest price in ', mr.p_type, ' is $', mr.max_price) AS max_price_info
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN MarketSegments ms ON ms.c_mktsegment = o.o_orderstatus
JOIN MaxRetailPrice mr ON mr.max_price = ps.ps_supplycost
WHERE o.o_orderdate BETWEEN '1996-01-01' AND '1997-01-01'
GROUP BY r.r_name, ms.order_count, mr.p_type, mr.max_price
HAVING COUNT(DISTINCT ps.ps_partkey) > 10
ORDER BY total_supply_cost DESC, nation_count ASC;