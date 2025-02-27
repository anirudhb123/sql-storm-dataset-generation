WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_custkey, c_name, c_acctbal, c_nationkey,
        CAST(c_name AS VARCHAR(255)) AS full_hierarchy, 1 AS level
    FROM customer
    WHERE c_acctbal > 1000
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_nationkey,
        CONCAT(ch.full_hierarchy, ' -> ', c.c_name) AS full_hierarchy, ch.level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_nationkey = ch.c_nationkey
    WHERE c.custkey <> ch.custkey AND ch.level < 5
),
SuppPartInfo AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty,
        COALESCE(SUM(ps.ps_supplycost) OVER (PARTITION BY ps.ps_partkey), 0) AS total_supplycost,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
ItemDetails AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
        CASE 
            WHEN p.p_retailprice > 100 THEN 'Expensive'
            WHEN p.p_retailprice BETWEEN 50 AND 100 THEN 'Moderately priced'
            ELSE 'Cheap'
        END AS price_category,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
)
SELECT ch.full_hierarchy, 
       SUM(i.p_retailprice) AS total_retail_value,
       AVG(si.total_supplycost) AS avg_supply_cost,
       COUNT(DISTINCT s.s_suppkey) AS distinct_suppliers,
       COUNT(DISTINCT c.c_custkey) FILTER (WHERE c.c_acctbal < 5000) AS low_balance_customers
FROM CustomerHierarchy ch
LEFT JOIN orders o ON o.o_custkey = ch.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN ItemDetails i ON i.p_partkey = l.l_partkey
LEFT JOIN SuppPartInfo si ON i.p_partkey = si.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey = si.ps_suppkey
GROUP BY ch.full_hierarchy
HAVING SUM(i.p_retailprice) > 10000 AND COUNT(DISTINCT s.s_suppkey) > 5
ORDER BY total_retail_value DESC, ch.level;
