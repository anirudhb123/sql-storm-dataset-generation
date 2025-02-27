WITH RECURSIVE price_analysis AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        ps.ps_availqty,
        (p.p_retailprice - ps.ps_supplycost) * ps.ps_availqty AS profit_margin,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY (p.p_retailprice - ps.ps_supplycost) DESC) as rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty IS NOT NULL
), filtered_nations AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT s.s_suppkey) as supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(DISTINCT s.s_suppkey) > 0
)
SELECT 
    n.n_name,
    pn.p_name,
    ISNULL(pa.profit_margin, 0) AS calculated_profit,
    CASE 
        WHEN pa.profit_margin IS NULL THEN 'No profit available'
        ELSE 
            CASE 
                WHEN pa.profit_margin > 100 THEN 'High Profit'
                WHEN pa.profit_margin BETWEEN 50 AND 100 THEN 'Moderate Profit'
                ELSE 'Low Profit'
            END
    END AS profitability_classification,
    COUNT(DISTINCT o.o_orderkey) OVER(PARTITION BY n.n_nationkey) AS total_orders,
    AVG(pa.profit_margin) OVER(PARTITION BY n.n_nationkey) AS avg_profit_per_nation
FROM filtered_nations n
LEFT JOIN price_analysis pa ON pa.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_nationkey = n.n_nationkey
)
LEFT JOIN part pn ON pn.p_partkey = pa.p_partkey
LEFT JOIN orders o ON o.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_partkey = pn.p_partkey
    AND l.l_returnflag = 'N'
)
WHERE pa.profit_margin IS NOT NULL OR n.supplier_count > 5
GROUP BY n.n_name, pn.p_name, pa.profit_margin
HAVING AVG(pa.profit_margin) > 75
ORDER BY profitability_classification DESC, calculated_profit DESC
OPTION (MAXRECURSION 5);
