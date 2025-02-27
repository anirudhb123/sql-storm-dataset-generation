WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_retailprice, ps.ps_availqty,
           ps.ps_supplycost, (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0

    UNION ALL

    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_retailprice, ps.ps_availqty,
           ps.ps_supplycost, (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > 0 AND sc.s_suppkey <> s.s_suppkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers,
    SUM(sc.profit_margin) AS total_profit_margin,
    AVG(sc.profit_margin) AS avg_profit_margin,
    MAX(sc.profit_margin) AS max_profit_margin,
    MIN(sc.profit_margin) AS min_profit_margin,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY SUM(sc.profit_margin) DESC) AS rank
FROM SupplyChain sc
JOIN supplier s ON sc.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE sc.profit_margin IS NOT NULL AND sc.ps_availqty > 10
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT s.s_suppkey) > 1 OR AVG(sc.profit_margin) > 0
ORDER BY total_profit_margin DESC
LIMIT 10;
