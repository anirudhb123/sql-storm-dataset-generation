WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, 0 AS level
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 100

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.n_nationkey, ps.ps_partkey, ps.ps_availqty, ps.ps_supplycost, sc.level + 1
    FROM SupplyChain sc
    JOIN supplier s ON sc.s_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 50
)

SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_retailprice,
    SUM(CASE 
            WHEN l.l_discount > 0.2 THEN l.l_extendedprice * (1 - l.l_discount) 
            ELSE l.l_extendedprice 
        END) AS total_price_after_discount,
    AVG(sc.ps_supplycost) AS avg_supply_cost,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_quantity) DESC) AS part_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN SupplyChain sc ON p.p_partkey = sc.ps_partkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND p.p_retailprice IS NOT NULL
    AND (l.l_returnflag IS NULL OR l.l_returnflag = 'R')
GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_retailprice
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_price_after_discount DESC, avg_supply_cost ASC
FETCH FIRST 10 ROWS ONLY;
