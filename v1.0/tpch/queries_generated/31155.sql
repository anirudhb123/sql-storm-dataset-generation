WITH RECURSIVE top_suppliers AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ts.level + 1
    FROM supplier s
    JOIN top_suppliers ts ON s.s_suppkey IN (
        SELECT ps_suppkey 
        FROM partsupp 
        WHERE ps_partkey IN (
            SELECT l_partkey 
            FROM lineitem 
            WHERE l_orderkey IN (
                SELECT o_orderkey 
                FROM orders 
                WHERE o_orderstatus = 'O' 
                AND o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
            )
        )
    )
)
, part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, 
           SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_value
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand, p.p_type
)
SELECT p.p_partkey, p.p_name, pd.total_supply_value,
       ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY pd.total_supply_value DESC) AS brand_rank,
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       MAX(s.s_acctbal) AS max_supplier_balance
FROM part_details pd
JOIN part p ON pd.p_partkey = p.p_partkey
LEFT JOIN top_suppliers s ON pd.total_supply_value > s.s_acctbal
GROUP BY p.p_partkey, p.p_name, pd.total_supply_value
HAVING pd.total_supply_value IS NOT NULL 
   AND (COUNT(DISTINCT s.s_suppkey) > 0 OR MAX(s.s_acctbal) IS NOT NULL)
ORDER BY brand_rank, p.p_name;
